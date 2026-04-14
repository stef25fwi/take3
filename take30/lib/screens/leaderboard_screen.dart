import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(leaderboardPeriodProvider);
    return PageWrap(
      title: 'Classement',
      trailing: const TakeHeaderButton(icon: Icons.bar_chart_rounded),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PeriodPill(label: 'Semaine', value: 'week', selected: period == 'week', baseTone: TakePillTone.yellow),
            _PeriodPill(label: 'Mois', value: 'month', selected: period == 'month', baseTone: TakePillTone.cyan),
            _PeriodPill(label: 'All-time', value: 'global', selected: period == 'global', baseTone: TakePillTone.purple),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '',
          subtitle: '',
          child: const Column(
            children: [
              TakeLeaderboardRow(rank: '🥇', name: 'Marie L.', scoreLabel: '2450pts', score: '2450'),
              Divider(color: Color(0x14FFFFFF), height: 1),
              TakeLeaderboardRow(rank: '🥈', name: 'Thomas K.', scoreLabel: '2180pts', score: '2180'),
              Divider(color: Color(0x14FFFFFF), height: 1),
              TakeLeaderboardRow(rank: '🥉', name: 'Sara N.', scoreLabel: '1920pts', score: '1920'),
              TakeLeaderboardRow(rank: '7', name: 'Stef (toi)', scoreLabel: '1340pts', score: '1340', highlight: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodPill extends ConsumerWidget {
  const _PeriodPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.baseTone,
  });

  final String label;
  final String value;
  final bool selected;
  final TakePillTone baseTone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TakePillButton(
      label: label,
      tone: selected ? TakePillTone.yellow : baseTone,
      onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = value,
    );
  }
}
