import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'mock_data.dart';
import '../utils/assets.dart';

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
  AuthService._();

  static final AuthService _instance = AuthService._();

  factory AuthService() => _instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || !email.contains('@')) {
      _setLoading(false);
      return const AuthResult.failure('Email invalide');
    }
    if (password.length < 4) {
      _setLoading(false);
      return const AuthResult.failure('Mot de passe trop court');
    }

    _currentUser = MockData.users.first;
    _error = null;
    _setLoading(false);
    notifyListeners();
    return AuthResult.success(_currentUser);
  }

  Future<AuthResult> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(seconds: 1));

    if (username.trim().length < 3) {
      _setLoading(false);
      return const AuthResult.failure('Pseudo trop court');
    }
    if (!email.contains('@')) {
      _setLoading(false);
      return const AuthResult.failure('Email invalide');
    }
    if (password.length < 4) {
      _setLoading(false);
      return const AuthResult.failure('Mot de passe trop court');
    }

    _currentUser = UserModel(
      id: 'u_new_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      displayName: username,
      avatarUrl: Take30Assets.avatarCurrentUser,
    );
    _error = null;
    _setLoading(false);
    notifyListeners();
    return AuthResult.success(_currentUser);
  }

  Future<AuthResult> loginWithGoogle() async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    _currentUser = MockData.users.first;
    _error = null;
    _setLoading(false);
    notifyListeners();
    return AuthResult.success(_currentUser);
  }

  Future<AuthResult> loginWithApple() async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    _currentUser = MockData.users.first;
    _error = null;
    _setLoading(false);
    notifyListeners();
    return AuthResult.success(_currentUser);
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _setLoading(false);
    return email.contains('@');
  }

  Future<void> logout() async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _error = null;
    _setLoading(false);
    notifyListeners();
  }

  Future<void> checkPersistedAuth() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}