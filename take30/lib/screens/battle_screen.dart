import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duel = ref.watch(duelProvider);

    return duel.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (item) => PageWrap(
        title: 'Battle',
        trailing: const TakePill(label: '● EN DIRECT', tone: TakePillTone.red),
        showBottomNav: true,
        activeTab: TakeTab.battle,
        children: [
          SectionCard(
            title: 'Battle #42',
            subtitle: 'Duel du soir • thème « Mouvement »',
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TakeCountdownBox(value: '02', label: 'h'),
                    SizedBox(width: 8),
                    TakeCountdownBox(value: '15', label: 'm'),
                    SizedBox(width: 8),
                    TakeCountdownBox(value: '33', label: 's'),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '126 participants',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BattleSide(
                  label: 'Marie L.',
                  initials: 'M',
                  score: '58%',
                  voted: item.userVote == null ? true : item.userVote == 0,
                  onTap: item.userVote == null ? () => ref.read(duelProvider.notifier).vote(0) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BattleSide(
                  label: 'Thomas K.',
                  initials: 'T',
                  score: '42%',
                  voted: item.userVote == 1,
                  colors: const [Color(0xFF6C5CE7), Color(0xFF00D4FF)],
                  onTap: item.userVote == null ? () => ref.read(duelProvider.notifier).vote(1) : null,
                ),
              ),
            ],
          ),
          if (item.userVote != null)
            SectionCard(
              title: 'Vote enregistré',
              subtitle: item.userVote == 0
                  ? 'Tu as voté pour Marie L.'
                  : 'Tu as voté pour Thomas K.',
              icon: Icons.how_to_vote_outlined,
            ),
        ],
      ),
    );
  }
}

class _BattleSide extends StatelessWidget {
  const _BattleSide({
    required this.label,
    required this.initials,
    required this.score,
    required this.voted,
    this.onTap,
    this.colors = const [Color(0xFF00D4FF), Color(0xFF6C5CE7)],
  });

  final String label;
  final String initials;
  final String score;
  final bool voted;
  final VoidCallback? onTap;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: voted ? const Color(0x1400D4FF) : const Color(0xFF121A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: voted ? const Color(0xFF00D4FF) : const Color(0x14FFFFFF)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TakeAvatar(label: initials, colors: colors),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(score, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('voté', style: TextStyle(color: Color(0x99FFFFFF))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
