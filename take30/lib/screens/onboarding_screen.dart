import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../theme/take30_screen_themes.dart';
import '../widgets/take30_logo.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T30Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Take30Logo(height: 52),
              ),
              const SizedBox(height: 28),
              const Expanded(
                child: _HeroCollagePlaceholder(),
              ),
              const SizedBox(height: 28),
              Text(
                'Rejoue des scènes\n& deviens viral',
                textAlign: TextAlign.center,
                style: T30Text.h1.copyWith(
                  fontSize: 32,
                  color: T30Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.03,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 18),
              Column(
                children: [
                  Text(
                    'Scènes quotidiennes',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duels',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classements',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Découverte de talents',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: T30Colors.ctaGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(255, 184, 0, 0.22),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRouter.auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Commencer',
                      style: T30Text.buttonPrimary.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: T30Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => context.go('${AppRouter.auth}?tab=login'),
                child: Text(
                  'Se connecter',
                  style: T30Text.bodyMedium.copyWith(
                    color: T30Colors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCollagePlaceholder extends StatelessWidget {
  const _HeroCollagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = width * 0.34;
        final cardHeight = height * 0.55;

        return Stack(
          children: [
            Positioned(
              left: width * 0.04,
              top: height * 0.18,
              child: _PhotoSlot(
                width: cardWidth,
                height: cardHeight,
                label: '1 pic',
                angle: -0.14,
              ),
            ),
            Positioned(
              left: width * 0.33,
              top: height * 0.02,
              child: _PhotoSlot(
                width: cardWidth * 1.02,
                height: cardHeight * 1.08,
                label: '2 pic',
                angle: 0.02,
                highlighted: true,
              ),
            ),
            Positioned(
              right: width * 0.04,
              top: height * 0.20,
              child: _PhotoSlot(
                width: cardWidth,
                height: cardHeight,
                label: '3 pic',
                angle: 0.15,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.width,
    required this.height,
    required this.label,
    required this.angle,
    this.highlighted = false,
  });

  final double width;
  final double height;
  final String label;
  final double angle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: highlighted
                ? const [Color(0xFF2A2A2F), Color(0xFF111111)]
                : const [Color(0xFF202025), Color(0xFF0C0C0F)],
          ),
          border: Border.all(
            color: highlighted
                ? const Color(0x33FFB800)
                : const Color(0x22FFFFFF),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.30),
              blurRadius: 22,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  label,
                  style: T30Text.bodyMedium.copyWith(
                    color: T30Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
