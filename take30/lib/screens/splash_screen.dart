import 'package:flutter/material.dart';
import '../theme/take30_screen_themes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreenTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SplashScreenTheme.glow.withValues(
                      alpha: SplashScreenTheme.glowOpacity,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Take30', style: T30Text.logo),
                const SizedBox(height: 12),
                Text(
                  'Prouve ton talent\nen 30 secondes',
                  textAlign: TextAlign.center,
                  style: T30Text.body.copyWith(
                    color: T30Colors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: SplashScreenTheme.homePill,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
