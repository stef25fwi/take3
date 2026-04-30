import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:take30/main.dart';
import 'package:take30/models/models.dart';
import 'package:take30/providers/providers.dart';
import 'package:take30/router/router.dart';
import 'package:take30/services/auth_service.dart';

class _FakeAuthService extends AuthServiceBase {
  @override
  UserModel? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> checkPersistedAuth() async {}

  @override
  Future<AuthResult> loginDemo() async => const AuthResult.failure('unused');

  @override
  Future<AuthResult> loginWithApple() async => const AuthResult.failure('unused');

  @override
  Future<AuthResult> loginWithGoogle() async => const AuthResult.failure('unused');

  @override
  Future<AuthResult> loginWithIdentifier({
    required String identifier,
    required String password,
  }) async => const AuthResult.failure('unused');

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResult> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async => const AuthResult.failure('unused');
}

void main() {
  testWidgets('l application affiche Take30', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final fakeAuthService = _FakeAuthService();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SizedBox(key: Key('app_test_home')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWith((ref) => fakeAuthService),
          routerProvider.overrideWithValue(router),
        ],
        child: const Take30App(),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('take30_app_root')), findsOneWidget);
    expect(find.byKey(const Key('app_test_home')), findsOneWidget);
  });
}
