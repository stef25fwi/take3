import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TakeScreenScaffold(
      title: '',
      showHeader: false,
      scrollable: false,
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFB800), Color(0xFF00D4FF)],
              ).createShader(bounds),
              child: const Text(
                'Take30',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créer. Partager. Briller.',
              style: TextStyle(fontSize: 16, color: Color(0x99FFFFFF)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.go(AppRouter.onboarding),
                child: const Text('Commencer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
