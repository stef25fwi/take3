import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _onAuthStateChanged(fa.User? fbUser) async {
    if (fbUser == null) {
      _currentUser = null;
      _api.setCurrentUser(null);
      notifyListeners();
      return;
    }
    final profile = await _loadOrCreateProfile(fbUser);
    _currentUser = profile;
    _api.setCurrentUser(profile);
    await _syncFcmToken(fbUser.uid);
    notifyListeners();
  }

  Future<UserModel?> _loadOrCreateProfile(fa.User fbUser) async {
    final existing = await _api.users.getById(fbUser.uid);
    if (existing != null) return existing;
    final fallback = UserModel(
      id: fbUser.uid,
      username: _deriveUsername(fbUser),
      displayName: fbUser.displayName ?? _deriveUsername(fbUser),
      avatarUrl: fbUser.photoURL ?? Take30Assets.avatarCurrentUser,
      createdAt: DateTime.now(),
    );
    await _api.users.createProfile(fallback);
    return fallback;
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
      _currentUser = user;
      _api.setCurrentUser(user);
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
        createdAt: DateTime.now(),
      );
      await _api.users.createProfile(user);
      _currentUser = user;
      _api.setCurrentUser(user);
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
        final cred = await _auth.signInWithPopup(provider);
        final user = await _loadOrCreateProfile(cred.user!);
        _currentUser = user;
        _api.setCurrentUser(user);
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
      _currentUser = user;
      _api.setCurrentUser(user);
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
      _currentUser = user;
      _api.setCurrentUser(user);
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
    _currentUser = null;
    _api.setCurrentUser(null);
    _error = null;
    _setLoading(false);
  }

  Future<void> checkPersistedAuth() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return;
    final user = await _api.users.getById(fbUser.uid);
    _currentUser = user;
    _api.setCurrentUser(user);
    notifyListeners();
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
      default:
        return e.message ?? 'Erreur d\'authentification';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}