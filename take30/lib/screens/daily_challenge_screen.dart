import 'package:flutter/material.dart';

import '../widgets/shared_widgets.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageWrap(
      title: 'Défi du jour',
      children: [
        SectionCard(
          title: 'Objectif',
          subtitle: 'Raconter une histoire courte en 3 plans maximum.',
        ),
        SectionCard(
          title: 'Temps',
          subtitle: '30 minutes pour préparer et tourner.',
        ),
        SectionCard(
          title: 'Récompense',
          subtitle: 'Badge créatif + points bonus.',
        ),
      ],
    );
  }
}
