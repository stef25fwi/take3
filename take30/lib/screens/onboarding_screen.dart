import 'package:flutter/material.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Bienvenue',
      children: [
        const SectionCard(
          title: 'Créer en 30 minutes',
          subtitle: 'Prépare, tourne et publie rapidement chaque scène.',
        ),
        const SectionCard(
          title: 'Découvrir',
          subtitle: 'Explore des idées, défis et inspirations.',
        ),
        const SectionCard(
          title: 'Progresser',
          subtitle: 'Suis ton niveau, tes badges et ton classement.',
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRouter.auth),
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}
