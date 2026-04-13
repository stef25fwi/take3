import 'package:flutter/material.dart';

import '../widgets/shared_widgets.dart';

class BadgesStatsScreen extends StatelessWidget {
  const BadgesStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Badges et stats',
      children: const [
        Row(
          children: [
            Expanded(child: InfoStat(label: 'Badges', value: '3')),
            SizedBox(width: 8),
            Expanded(child: InfoStat(label: 'Takes', value: '12')),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: InfoStat(label: 'Temps moyen', value: '28 min')),
            SizedBox(width: 8),
            Expanded(child: InfoStat(label: 'Score', value: '87%')),
          ],
        ),
        SizedBox(height: 16),
        SectionCard(title: 'Créatif', subtitle: 'Débloqué grâce au défi du jour', icon: Icons.auto_awesome_outlined),
        SectionCard(title: 'Régulier', subtitle: '5 jours actifs consécutifs', icon: Icons.calendar_month_outlined),
        SectionCard(title: 'Challenger', subtitle: 'Participation aux battles communauté', icon: Icons.emoji_events_outlined),
      ],
    );
  }
}
