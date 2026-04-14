import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duelProvider);
    return Scaffold(
      backgroundColor: BattleTheme.background,
      appBar: AppBar(
        backgroundColor: BattleTheme.appBarBg,
        elevation: 0,
        title: Text(
          'Battle',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '● EN DIRECT',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
          : state.duel == null
              ? Center(
                  child: Text(
                    'Aucune battle disponible',
                    style: GoogleFonts.dmSans(color: AppColors.white),
                  ),
                )
              : _BattleBody(
                  duel: state.duel!,
                  onVote: (choice) => ref.read(duelProvider.notifier).vote(choice),
                ),
    );
  }
}

class _BattleBody extends StatelessWidget {
  const _BattleBody({required this.duel, required this.onVote});

  final DuelModel duel;
  final void Function(int) onVote;

  @override
  Widget build(BuildContext context) {
    final voted = duel.userVote != null;
    final remaining = duel.expiresAt.difference(DateTime.now());
    final hours = remaining.inHours.clamp(0, 99);
    final minutes = remaining.inMinutes.remainder(60).clamp(0, 59);
    final seconds = remaining.inSeconds.remainder(60).clamp(0, 59);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Text(
                  'Battle #${duel.id}',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duel du soir • thème « ${duel.sceneA.category} »',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CountdownBox(value: hours.toString().padLeft(2, '0'), label: 'h'),
                    const SizedBox(width: 8),
                    _CountdownBox(value: minutes.toString().padLeft(2, '0'), label: 'm'),
                    const SizedBox(width: 8),
                    _CountdownBox(value: seconds.toString().padLeft(2, '0'), label: 's'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${duel.totalVotes} participants',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BattleSide(
                  scene: duel.sceneA,
                  percent: duel.percentA,
                  voted: duel.userVote == 0,
                  isLeading: duel.percentA >= duel.percentB,
                  onTap: voted ? null : () => onVote(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BattleSide(
                  scene: duel.sceneB,
                  percent: duel.percentB,
                  voted: duel.userVote == 1,
                  isLeading: duel.percentB > duel.percentA,
                  onTap: voted ? null : () => onVote(1),
                ),
              ),
            ],
          ),
          if (voted) ...[
            const SizedBox(height: 16),
            Text(
              'Tu as voté pour ${duel.userVote == 0 ? duel.sceneA.author.displayName : duel.sceneB.author.displayName}',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.yellow,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BattleSide extends StatelessWidget {
  const _BattleSide({
    required this.scene,
    required this.percent,
    required this.voted,
    required this.isLeading,
    this.onTap,
  });

  final SceneModel scene;
  final double percent;
  final bool voted;
  final bool isLeading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: voted ? AppColors.cyan.withValues(alpha: 0.08) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: voted ? AppColors.cyan : AppColors.borderSubtle,
          ),
          boxShadow: isLeading
              ? [
                  BoxShadow(
                    color: AppColors.yellow.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            UserAvatar(url: scene.author.avatarUrl, size: 52),
            const SizedBox(height: 10),
            Text(
              scene.author.displayName,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(percent * 100).round()}%',
              style: GoogleFonts.dmSans(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              voted ? 'voté' : 'voter',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              scene.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 62),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
