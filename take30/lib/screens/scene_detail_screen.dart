import 'package:flutter/material.dart';

import '../widgets/shared_widgets.dart';

class SceneDetailScreen extends StatelessWidget {
  const SceneDetailScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final description = switch (title) {
      'Cuisine rapide' => 'Préparer une recette courte avec un rythme vif et des plans serrés.',
      'Mini reportage' => 'Montrer une situation réelle avec début, milieu et fin très claire.',
      _ => 'Créer une scène simple avec un visuel fort et une ambiance identifiable.',
    };

    return PageWrap(
      title: title,
      children: [
        SectionCard(
          title: 'Concept',
          subtitle: description,
          icon: Icons.lightbulb_outline,
        ),
        const SectionCard(
          title: 'Conseil',
          subtitle: 'Privilégier la lumière naturelle, un cadrage stable et une accroche rapide.',
          icon: Icons.tips_and_updates_outlined,
        ),
        const SectionCard(
          title: 'Objectif',
          subtitle: 'Produire une version prête à publier en moins de 30 minutes.',
          icon: Icons.flag_outlined,
        ),
      ],
    );
  }
}
