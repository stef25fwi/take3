import 'package:flutter/material.dart';

import '../../models/models.dart';

class BattleStatusBadge extends StatelessWidget {
  const BattleStatusBadge({super.key, required this.status});

  final BattleStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BattleStatus.challengeSent => ('Défi envoyé', const Color(0xFF8E8E93)),
      BattleStatus.declined => ('Refusé', const Color(0xFFFF5C6C)),
      BattleStatus.accepted || BattleStatus.sceneAssigned || BattleStatus.inPreparation =>
        ('En préparation', const Color(0xFFFFB800)),
      BattleStatus.waitingChallengerSubmission || BattleStatus.waitingOpponentSubmission =>
        ('En attente de l’adversaire', const Color(0xFFFFB800)),
      BattleStatus.readyToPublish => ('Prête', const Color(0xFF00D4FF)),
      BattleStatus.published || BattleStatus.votingOpen => ('Vote ouvert', const Color(0xFF00D084)),
      BattleStatus.ended => ('Terminée', const Color(0xFF6C5CE7)),
      BattleStatus.cancelled => ('Annulée', const Color(0xFFFF5C6C)),
      BattleStatus.forfeit => ('Victoire par forfait', const Color(0xFFFF5C6C)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
