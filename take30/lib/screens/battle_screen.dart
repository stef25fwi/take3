import 'package:flutter/material.dart';

import '../widgets/shared_widgets.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Battle',
      children: const [
        SectionCard(title: 'Adversaire', subtitle: 'Créateur aléatoire prêt pour un duel'),
        SectionCard(title: 'Critère', subtitle: 'Originalité, rythme et narration'),
        SectionCard(title: 'Vote', subtitle: 'La communauté départage les deux créations'),
      ],
    );
  }
}
