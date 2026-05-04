import 'package:flutter/material.dart';

import '../../models/models.dart';

class BattleCandidateFaceoff extends StatelessWidget {
  const BattleCandidateFaceoff({
    super.key,
    required this.battle,
    this.onTapChallenger,
    this.onTapOpponent,
  });

  final BattleModel battle;
  final VoidCallback? onTapChallenger;
  final VoidCallback? onTapOpponent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Candidate(
            name: battle.challengerName,
            photoUrl: battle.challengerPhotoUrl,
            alignment: CrossAxisAlignment.start,
            onTap: onTapChallenger,
          ),
        ),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
          ),
          child: Text(
            'VS',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: _Candidate(
            name: battle.opponentName,
            photoUrl: battle.opponentPhotoUrl,
            alignment: CrossAxisAlignment.end,
            onTap: onTapOpponent,
          ),
        ),
      ],
    );
  }
}

class _Candidate extends StatelessWidget {
  const _Candidate({
    required this.name,
    required this.photoUrl,
    required this.alignment,
    required this.onTap,
  });

  final String name;
  final String? photoUrl;
  final CrossAxisAlignment alignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl == null || photoUrl!.isEmpty
                ? Text(name.isEmpty ? '?' : name.characters.first.toUpperCase())
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            name.isEmpty ? 'Candidat' : name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
