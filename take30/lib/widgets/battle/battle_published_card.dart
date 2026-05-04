import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'battle_candidate_faceoff.dart';
import 'battle_countdown_chip.dart';
import 'battle_status_badge.dart';
import 'follow_battle_button.dart';

class BattlePublishedCard extends StatelessWidget {
  const BattlePublishedCard({
    super.key,
    required this.battle,
    this.onTap,
    this.onTapChallenger,
    this.onTapOpponent,
  });

  final BattleModel battle;
  final VoidCallback? onTap;
  final VoidCallback? onTapChallenger;
  final VoidCallback? onTapOpponent;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BattleStatusBadge(status: battle.status),
                  const Spacer(),
                  BattleCountdownChip(remaining: battle.timeRemaining),
                ],
              ),
              const SizedBox(height: 14),
              BattleCandidateFaceoff(
                battle: battle,
                onTapChallenger: onTapChallenger,
                onTapOpponent: onTapOpponent,
              ),
              const SizedBox(height: 12),
              Text(
                battle.sceneTitle ?? battle.themeTitle ?? 'Scène Battle Take60',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text('Même scène. Même délai. Deux interprétations. Un seul gagnant.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${battle.totalVotes} votes')),
                  Chip(label: Text('${battle.followersCount} suivent')),
                  FollowBattleButton(battleId: battle.id),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
