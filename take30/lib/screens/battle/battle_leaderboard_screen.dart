import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/battle_providers.dart';
import '../../router/router.dart';
import '../../widgets/battle/battle_countdown_chip.dart';
import '../../widgets/battle/battle_status_badge.dart';

class BattleLeaderboardScreen extends ConsumerWidget {
  const BattleLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleLeaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Classement Battle')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Classement Battle indisponible.')),
        data: (battles) {
          if (battles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucune battle classée pour le moment.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: battles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final battle = battles[index];
              return _BattleLeaderboardTile(
                rank: index + 1,
                battle: battle,
              );
            },
          );
        },
      ),
    );
  }
}

class _BattleLeaderboardTile extends StatelessWidget {
  const _BattleLeaderboardTile({
    required this.rank,
    required this.battle,
  });

  final int rank;
  final BattleModel battle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRouter.battlePath(battle.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      '$rank',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${battle.challengerName} vs ${battle.opponentName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  BattleStatusBadge(status: battle.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                battle.sceneTitle ?? battle.themeTitle ?? 'Scène Battle Take60',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Score ${battle.battleScore.toStringAsFixed(0)}')),
                  Chip(label: Text('Tendance ${battle.trendingScore.toStringAsFixed(0)}')),
                  Chip(label: Text('${battle.totalVotes} votes')),
                  Chip(label: Text('${battle.followersCount} suivent')),
                  if (battle.isFeatured) const Chip(label: Text('À la une')),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: BattleCountdownChip(remaining: battle.timeRemaining),
              ),
            ],
          ),
        ),
      ),
    );
  }
}