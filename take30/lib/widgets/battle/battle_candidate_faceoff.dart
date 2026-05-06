import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'battle_outlined_text.dart';

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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        Expanded(
          child: _Candidate(
            name: battle.challengerName,
            photoUrl: battle.challengerPhotoUrl,
            alignment: CrossAxisAlignment.start,
            onTap: onTapChallenger,
            outlinedText: isLight,
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
            outlinedText: isLight,
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
    required this.outlinedText,
  });

  final String name;
  final String? photoUrl;
  final CrossAxisAlignment alignment;
  final VoidCallback? onTap;
  final bool outlinedText;

  @override
  Widget build(BuildContext context) {
    final label = name.isEmpty ? 'Candidat' : name;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        );
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.18),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 31,
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Text(name.isEmpty ? '?' : name.characters.first.toUpperCase())
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          outlinedText
              ? BattleOutlinedText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                  fillColor: Colors.white,
                  strokeColor: Colors.black,
                  strokeWidth: 2.4,
                )
              : Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
        ],
      ),
    );
  }
}
