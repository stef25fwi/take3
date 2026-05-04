import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/battle_providers.dart';
import '../../router/router.dart';
import '../../widgets/battle/battle_preparing_card.dart';
import '../../widgets/battle/battle_published_card.dart';

class BattleListScreen extends ConsumerWidget {
  const BattleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredBattlesProvider);
    final trending = ref.watch(trendingBattlesProvider);
    final soonClosing = ref.watch(soonClosingBattlesProvider);
    final published = ref.watch(homePublishedBattlesProvider);
    final preparing = ref.watch(homePreparingBattlesProvider);
    final expected = ref.watch(mostExpectedBattlesProvider);
    final followed = ref.watch(followedCandidatesBattlesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Battles Take60')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          const _BattleIntro(),
          _BattleSection(
            title: 'Battles à la une',
            state: featured,
            showWhenEmpty: false,
            itemBuilder: (battle) => BattlePublishedCard(
              battle: battle,
              onTap: () => context.go(AppRouter.battlePath(battle.id)),
              onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
              onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
            ),
          ),
          _BattleSection(
            title: 'Battles tendance',
            state: trending,
            showWhenEmpty: false,
            itemBuilder: (battle) => battle.isPublished
                ? BattlePublishedCard(
                    battle: battle,
                    onTap: () => context.go(AppRouter.battlePath(battle.id)),
                    onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                    onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                  )
                : BattlePreparingCard(
                    battle: battle,
                    onTap: () => context.go(AppRouter.battlePath(battle.id)),
                    onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                    onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                  ),
          ),
          _BattleSection(
            title: 'Fin de vote imminente',
            state: soonClosing,
            showWhenEmpty: false,
            itemBuilder: (battle) => BattlePublishedCard(
              battle: battle,
              onTap: () => context.go(AppRouter.battlePath(battle.id)),
              onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
              onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
            ),
          ),
          _BattleSection(
            title: 'Battles en ligne',
            state: published,
            itemBuilder: (battle) => BattlePublishedCard(
              battle: battle,
              onTap: () => context.go(AppRouter.battlePath(battle.id)),
              onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
              onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
            ),
          ),
          _BattleSection(
            title: 'Battles en préparation',
            state: preparing,
            itemBuilder: (battle) => BattlePreparingCard(
              battle: battle,
              onTap: () => context.go(AppRouter.battlePath(battle.id)),
              onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
              onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
            ),
          ),
          _BattleSection(
            title: 'Battles les plus attendues',
            state: expected,
            itemBuilder: (battle) => BattlePreparingCard(
              battle: battle,
              onTap: () => context.go(AppRouter.battlePath(battle.id)),
            ),
          ),
          _BattleSection(
            title: 'Mes candidats suivis',
            state: followed,
            itemBuilder: (battle) => BattlePublishedCard(
              battle: battle,
              onTap: () => context.go(AppRouter.battlePath(battle.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleIntro extends StatelessWidget {
  const _BattleIntro();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duel d’interprétation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('Même scène. Même délai. Deux interprétations. Un seul gagnant.'),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRouter.battleLeaderboard),
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('Voir le classement Battle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleSection extends StatelessWidget {
  const _BattleSection({
    required this.title,
    required this.state,
    required this.itemBuilder,
    this.showWhenEmpty = true,
  });

  final String title;
  final AsyncValue<List<BattleModel>> state;
  final Widget Function(BattleModel battle) itemBuilder;
  final bool showWhenEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          state.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (_, __) => const Text('Battles indisponibles pour le moment.'),
            data: (battles) {
              if (battles.isEmpty) {
                if (!showWhenEmpty) {
                  return const SizedBox.shrink();
                }
                return const Text('Aucune battle à afficher.');
              }
              return Column(
                children: [
                  for (final battle in battles) ...[
                    itemBuilder(battle),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
