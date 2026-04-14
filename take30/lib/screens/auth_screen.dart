import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController(text: 'demo@take30.app');
  final _passwordController = TextEditingController(text: 'demo123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    final auth = ref.read(authServiceProvider);
    final result = await auth.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (result.success) {
      context.go(AppRouter.home);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Erreur de connexion')),
    );
  }

  Future<void> _registerDemo() async {
    final auth = ref.read(authServiceProvider);
    final result = await auth.registerWithEmail(
      username: 'take30_demo',
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (result.success) {
      context.go(AppRouter.home);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Erreur de création de compte')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);

    return PageWrap(
      title: 'Connexion',
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Mot de passe'),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _loginWithEmail,
          child: Text(auth.isLoading ? 'Connexion...' : 'Entrer'),
        ),
        OutlinedButton(
          onPressed: auth.isLoading ? null : _registerDemo,
          child: const Text('Créer un compte démo'),
        ),
        TextButton(
          onPressed: auth.isLoading
              ? null
              : () async {
                  final result = await ref.read(authServiceProvider).loginWithGoogle();
                  if (!mounted || !result.success) {
                    return;
                  }
                  context.go(AppRouter.home);
                },
          child: const Text('Continuer avec Google'),
        ),
      ],
    );
  }
}
