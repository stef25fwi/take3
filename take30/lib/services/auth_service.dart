import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/models.dart';
import '../utils/assets.dart';
import 'api_service.dart';

enum AuthProvider { email, google, apple }

class AuthResult {
  const AuthResult.success(this.user)
      : success = true,
        error = null;

  const AuthResult.failure(this.error)
      : success = false,
        user = null;

  final bool success;
  final UserModel? user;
  final String? error;
}

class AuthService extends ChangeNotifier {
  AuthService._() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;
  final ApiService _api = ApiService();

  static const String _demoEmail = 'demo@take30.app';
  static const String _demoUsername = 'demo_take30';
  static const String _demoDisplayName = 'Mode Demo';
  static const String _demoSessionPrefKey = 'take30.demo_session';

  UserModel? _currentUser;
  bool _isLocalDemoSession = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isLocalDemoSession || _auth.currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _onAuthStateChanged(fa.User? fbUser) async {
    if (fbUser == null) {
      if (_isLocalDemoSession && _currentUser != null) {
        notifyListeners();
        return;
      }
      _setSessionUser(null);
      notifyListeners();
      return;
    }
    final profile = await _loadOrCreateProfile(fbUser);
    _setSessionUser(profile);
    await _syncFcmToken(fbUser.uid);
    notifyListeners();
  }

  Future<UserModel?> _loadOrCreateProfile(
    fa.User fbUser, {
    String? preferredUsername,
    String? preferredDisplayName,
    String? preferredAvatarUrl,
  }) async {
    final existing = await _api.users.getById(fbUser.uid);
    final email = fbUser.email?.trim();
    if (existing != null) {
      if ((existing.email == null || existing.email!.isEmpty) &&
          email != null &&
          email.isNotEmpty) {
        try {
          await _api.users.updateProfile(fbUser.uid, {'email': email});
          return UserModel(
            id: existing.id,
            username: existing.username,
            displayName: existing.displayName,
            avatarUrl: existing.avatarUrl,
            email: email,
            bio: existing.bio,
            isVerified: existing.isVerified,
            scenesCount: existing.scenesCount,
            followersCount: existing.followersCount,
            likesCount: existing.likesCount,
            totalViews: existing.totalViews,
            approvalRate: existing.approvalRate,
            sharesCount: existing.sharesCount,
            badges: existing.badges,
            isFollowing: existing.isFollowing,
            isAdmin: existing.isAdmin,
            createdAt: existing.createdAt,
            lastActiveAt: existing.lastActiveAt,
            fcmTokens: existing.fcmTokens,
          );
        } on FirebaseException catch (error) {
          if (!_isOfflineFirestoreError(error)) {
            rethrow;
          }
        }
      }
      return existing;
    }
    if (email != null && email.isNotEmpty) {
      final existingByEmail = await _api.users.getByEmail(email);
      if (existingByEmail != null) {
        final migrated = UserModel(
          id: fbUser.uid,
          username: existingByEmail.username,
          displayName: existingByEmail.displayName,
          avatarUrl: existingByEmail.avatarUrl,
          email: email,
          bio: existingByEmail.bio,
          isVerified: existingByEmail.isVerified,
          scenesCount: existingByEmail.scenesCount,
          followersCount: existingByEmail.followersCount,
          likesCount: existingByEmail.likesCount,
          totalViews: existingByEmail.totalViews,
          approvalRate: existingByEmail.approvalRate,
          sharesCount: existingByEmail.sharesCount,
          badges: existingByEmail.badges,
          isFollowing: existingByEmail.isFollowing,
          isAdmin: existingByEmail.isAdmin,
          createdAt: existingByEmail.createdAt,
          lastActiveAt: existingByEmail.lastActiveAt,
          fcmTokens: existingByEmail.fcmTokens,
        );
        try {
          await _api.users.createProfile(migrated);
        } on FirebaseException catch (error) {
          if (!_isOfflineFirestoreError(error)) {
            rethrow;
          }
        }
        return migrated;
      }
    }
    final fallback = _buildFallbackProfile(
      fbUser,
      preferredUsername: preferredUsername,
      preferredDisplayName: preferredDisplayName,
      preferredAvatarUrl: preferredAvatarUrl,
    );
    try {
      await _api.users.createProfile(fallback);
    } on FirebaseException catch (error) {
      if (!_isOfflineFirestoreError(error)) {
        rethrow;
      }
      debugPrint('Profile creation deferred while offline: ${error.code}');
    }
    return fallback;
  }

  UserModel _buildFallbackProfile(
    fa.User fbUser, {
    String? preferredUsername,
    String? preferredDisplayName,
    String? preferredAvatarUrl,
  }) {
    final username = preferredUsername ?? _deriveUsername(fbUser);
    return UserModel(
      id: fbUser.uid,
      username: username,
      displayName: preferredDisplayName ?? fbUser.displayName ?? username,
      avatarUrl:
          preferredAvatarUrl ?? fbUser.photoURL ?? Take30Assets.avatarCurrentUser,
      email: fbUser.email?.trim(),
      createdAt: DateTime.now(),
    );
  }

  UserModel _buildLocalDemoUser() {
    return UserModel(
      id: 'demo_local',
      username: _demoUsername,
      displayName: _demoDisplayName,
      avatarUrl: Take30Assets.avatarCurrentUser,
      email: _demoEmail,
      isVerified: true,
      createdAt: DateTime.now(),
    );
  }

  void _setSessionUser(UserModel? user, {bool isLocalDemo = false}) {
    _isLocalDemoSession = isLocalDemo && user != null;
    _currentUser = user;
    _api.setCurrentUser(user);
  }

  Future<void> _persistDemoSession(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      await prefs.setBool(_demoSessionPrefKey, true);
    } else {
      await prefs.remove(_demoSessionPrefKey);
    }
  }

  Future<bool> _hasPersistedDemoSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoSessionPrefKey) ?? false;
  }

  String _deriveUsername(fa.User fbUser) {
    final email = fbUser.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'user_${fbUser.uid.substring(0, 6)}';
  }

  Future<void> _syncFcmToken(String uid) async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.users.addFcmToken(uid: uid, token: token);
      }
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _loadOrCreateProfile(cred.user!);
      _setSessionUser(user);
      _error = null;
      _setLoading(false);
      return AuthResult.success(user);
    } on fa.FirebaseAuthException catch (e) {
      _setLoading(false);
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      _setLoading(false);
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult> loginWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();
    if (cleanIdentifier.isEmpty) {
      return const AuthResult.failure('Email ou pseudo requis');
    }

    if (cleanIdentifier.contains('@')) {
      return loginWithEmail(email: cleanIdentifier, password: password);
    }

    _setLoading(true);
    try {
      final profile = await _api.users.getByUsername(cleanIdentifier);
      final profileEmail = profile?.email?.trim();
      if (profileEmail == null || profileEmail.isEmpty) {
        _setLoading(false);
        return const AuthResult.failure(
          'Ce pseudo doit d\'abord se connecter avec son email une fois.',
        );
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: profileEmail,
        password: password,
      );
      final user = await _loadOrCreateProfile(cred.user!);
      _setSessionUser(user);
      _error = null;
      _setLoading(false);
      return AuthResult.success(user);
    } on fa.FirebaseAuthException catch (e) {
      _setLoading(false);
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      _setLoading(false);
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult> loginDemo() async {
    _setLoading(true);
    final user = _buildLocalDemoUser();
    _setSessionUser(user, isLocalDemo: true);
    await _persistDemoSession(true);
    _error = null;
    _setLoading(false);
    return AuthResult.success(user);
  }

  Future<AuthResult> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.length < 3) {
      return const AuthResult.failure('Pseudo trop court');
    }
    _setLoading(true);
    try {
      final taken = await _api.users.getByUsername(cleanUsername);
      if (taken != null) {
        _setLoading(false);
        return const AuthResult.failure('Pseudo déjà pris');
      }
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(cleanUsername);
      final user = UserModel(
        id: cred.user!.uid,
        username: cleanUsername,
        displayName: cleanUsername,
        avatarUrl: cred.user!.photoURL ?? Take30Assets.avatarCurrentUser,
        email: cred.user!.email?.trim(),
        createdAt: DateTime.now(),
      );
      await _api.users.createProfile(user);
      _setSessionUser(user);
      _error = null;
      _setLoading(false);
      return AuthResult.success(user);
    } on fa.FirebaseAuthException catch (e) {
      _setLoading(false);
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      _setLoading(false);
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    _setLoading(true);
    try {
      fa.OAuthCredential credential;
      if (kIsWeb) {
        final provider = fa.GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        provider.setCustomParameters({'prompt': 'select_account'});
        final cred = await _auth.signInWithPopup(provider);
        final user = await _loadOrCreateProfile(cred.user!);
        _setSessionUser(user);
        _error = null;
        _setLoading(false);
        return AuthResult.success(user);
      } else {
        final google = GoogleSignIn();
        final account = await google.signIn();
        if (account == null) {
          _setLoading(false);
          return const AuthResult.failure('Connexion annulée');
        }
        final auth = await account.authentication;
        credential = fa.GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
      }
      final cred = await _auth.signInWithCredential(credential);
      final user = await _loadOrCreateProfile(cred.user!);
      _setSessionUser(user);
      _setLoading(false);
      return AuthResult.success(user);
    } on fa.FirebaseAuthException catch (e) {
      _setLoading(false);
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      _setLoading(false);
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult> loginWithApple() async {
    _setLoading(true);
    try {
      if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS) {
        _setLoading(false);
        return const AuthResult.failure('Apple Sign-In indisponible');
      }
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = fa.OAuthProvider('apple.com').credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauth);
      final user = await _loadOrCreateProfile(cred.user!);
      _setSessionUser(user);
      _setLoading(false);
      return AuthResult.success(user);
    } on fa.FirebaseAuthException catch (e) {
      _setLoading(false);
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      _setLoading(false);
      return AuthResult.failure(e.toString());
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } catch (_) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _isLocalDemoSession = false;
    await _persistDemoSession(false);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null && !kIsWeb) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _api.users.removeFcmToken(uid: uid, token: token);
        }
      }
    } catch (_) {}
    await _auth.signOut();
    try {
      if (!kIsWeb) await GoogleSignIn().signOut();
    } catch (_) {}
    _setSessionUser(null);
    _error = null;
    _setLoading(false);
  }

  Future<void> checkPersistedAuth() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      final user = await _loadOrCreateProfile(fbUser) ??
          _buildFallbackProfile(fbUser);
      _setSessionUser(user);
      await _persistDemoSession(false);
      notifyListeners();
      return;
    }

    if (await _hasPersistedDemoSession()) {
      _setSessionUser(_buildLocalDemoUser(), isLocalDemo: true);
    }
    notifyListeners();
  }

  bool _isOfflineFirestoreError(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'failed-precondition' ||
        error.code == 'network-request-failed';
  }

  String _mapAuthError(fa.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Compte désactivé';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Identifiants incorrects';
      case 'email-already-in-use':
        return 'Email déjà utilisé';
      case 'weak-password':
        return 'Mot de passe trop faible (min 6 car.)';
      case 'network-request-failed':
        return 'Pas de connexion réseau';
      case 'popup-blocked':
        return 'La popup Google a été bloquée par le navigateur. Autorise les popups puis réessaie.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-cancelled':
        return 'Connexion Google annulée';
      case 'operation-not-supported-in-this-environment':
        return 'Connexion Google indisponible dans cet environnement navigateur';
      case 'unauthorized-domain':
        return 'Ce domaine n\'est pas autorisé pour la connexion Google dans Firebase';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec ce même email via une autre méthode de connexion';
      case 'operation-not-allowed':
        return 'Méthode de connexion non activée dans Firebase';
      default:
        return e.message ?? 'Erreur d\'authentification';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}