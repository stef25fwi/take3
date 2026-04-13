import 'package:flutter/material.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Connexion',
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(labelText: 'Mot de passe'),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.shell),
          child: const Text('Entrer'),
        ),
      ],
    );
  }
}
