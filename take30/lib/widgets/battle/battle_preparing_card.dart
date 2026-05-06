import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'battle_candidate_faceoff.dart';
import 'battle_countdown_chip.dart';
import 'battle_outlined_text.dart';
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final title = battle.sceneTitle ?? battle.themeTitle ?? 'La scène est tombée.';
    const subtitle = 'Les deux candidats préparent leur performance.';
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 14);
    return Card(
      color: isLight ? Colors.white : null,
      surfaceTintColor: isLight ? Colors.white : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLight ? const Color(0xFFD9DEE8) : Colors.transparent,
        ),
      ),
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
              isLight
                  ? BattleOutlinedText(
                      title,
                      style: titleStyle,
                      fillColor: Colors.white,
                      strokeColor: Colors.black,
                      strokeWidth: 2.6,
                    )
                  : Text(title, style: titleStyle),
              const SizedBox(height: 4),
              isLight
                  ? BattleOutlinedText(
                      subtitle,
                      style: subtitleStyle,
                      fillColor: Colors.white,
                      strokeColor: Colors.black,
                      strokeWidth: 2,
                    )
                  : const Text(subtitle),
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
