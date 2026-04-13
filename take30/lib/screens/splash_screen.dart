import 'package:flutter/material.dart';

import '../router/router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, size: 72, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            const Text('Take30', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.onboarding),
              child: const Text('Entrer dans l’app'),
            ),
          ],
        ),
      ),
    );
  }
}
