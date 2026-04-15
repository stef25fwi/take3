import 'package:flutter/material.dart';
import '../theme/take30_screen_themes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = const [
      ('🎬', 'Scènes quotidiennes'),
      ('⚔️', 'Défis & Duels'),
      ('🏆', 'Classements'),
      ('🌟', 'Découverte de talents'),
    ];

    return Scaffold(
      backgroundColor: OnboardingScreenTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/onboarding/onboarding_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: OnboardingScreenTheme.overlay,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Take30', style: T30Text.logo.copyWith(fontSize: 44)),
                  const SizedBox(height: 8),
                  Text(
                    'Rejoue des scènes\n& deviens viral',
                    style: T30Text.h1.copyWith(fontSize: 27),
                  ),
                  const Spacer(),
                  ...features.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: OnboardingScreenTheme.featureBox,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(e.$1),
                          ),
                          const SizedBox(width: 12),
                          Text(e.$2, style: T30Text.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: T30Buttons.primary(),
                      onPressed: () {},
                      child: Text('Commencer', style: T30Text.buttonPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: T30Buttons.outline(),
                      onPressed: () {},
                      child:
                          Text('Se connecter', style: T30Text.buttonSecondary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Créer un compte',
                      style: T30Text.caption.copyWith(
                        color: OnboardingScreenTheme.link,
                        decoration: TextDecoration.underline,
                        decorationColor: OnboardingScreenTheme.link,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
