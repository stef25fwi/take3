import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TakeScreenScaffold(
      title: '',
      showHeader: false,
      scrollable: false,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.35),
                  radius: 0.7,
                  colors: [Color(0x14FFB800), Colors.transparent],
                ),
              ),
              child: const Text('🎬', style: TextStyle(fontSize: 80)),
            ),
          ),
          const Text(
            'Ton film en 30 min',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enregistre, monte et publie des scènes créatives en un temps record, depuis ton téléphone.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.6, color: Color(0x99FFFFFF)),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OnboardingDot(active: true),
              SizedBox(width: 6),
              _OnboardingDot(),
              SizedBox(width: 6),
              _OnboardingDot(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.go(AppRouter.home),
              child: const Text('Suivant →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingDot extends StatelessWidget {
  const _OnboardingDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFB800) : const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
