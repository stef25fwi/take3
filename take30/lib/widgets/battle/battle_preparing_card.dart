import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'battle_candidate_faceoff.dart';
import 'battle_countdown_chip.dart';
import 'battle_status_badge.dart';
import 'follow_battle_button.dart';

class BattlePreparingCard extends StatelessWidget {
  const BattlePreparingCard({
    super.key,
    required this.battle,
    this.onTap,
    this.onPredict,
    this.onTapChallenger,
    this.onTapOpponent,
  });

  final BattleModel battle;
  final VoidCallback? onTap;
  final VoidCallback? onPredict;
  final VoidCallback? onTapChallenger;
  final VoidCallback? onTapOpponent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                battle.sceneTitle ?? battle.themeTitle ?? 'La scène est tombée.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text('Les deux candidats préparent leur performance.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FollowBattleButton(battleId: battle.id),
                  OutlinedButton.icon(
                    onPressed: onPredict,
                    icon: const Icon(Icons.auto_graph),
                    label: const Text('Faire mon pronostic'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
