import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'battle_published_card.dart';
import 'battle_preparing_card.dart';

class BattleHeroCard extends StatelessWidget {
  const BattleHeroCard({
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
    if (battle.isVotingOpen || battle.isPublished) {
      return BattlePublishedCard(
        battle: battle,
        onTap: onTap,
        onTapChallenger: onTapChallenger,
        onTapOpponent: onTapOpponent,
      );
    }
    return BattlePreparingCard(
      battle: battle,
      onTap: onTap,
      onTapChallenger: onTapChallenger,
      onTapOpponent: onTapOpponent,
    );
  }
}
