import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duelProvider);
    return Scaffold(
      backgroundColor: _BattlePalette.background,
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _BattlePalette.yellow),
            )
          : state.duel == null
              ? Center(
                  child: Text(
                    'Aucune battle disponible',
                    style: GoogleFonts.dmSans(
                      color: _BattlePalette.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
    final timer = [
      hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ].join(':');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050816), Color(0xFF070C1C), Color(0xFF050816)],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -80,
            left: -40,
            child: _BattleGlow(
              color: _BattlePalette.cyan,
              size: 220,
              opacity: 0.16,
            ),
          ),
          const Positioned(
            top: 180,
            right: -60,
            child: _BattleGlow(
              color: _BattlePalette.yellow,
              size: 240,
              opacity: 0.12,
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 116),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                            width: 126,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoPill(
                                icon: Icons.schedule_rounded,
                                label: 'Clôture dans $timer',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _BattlePalette.red.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _BattlePalette.red.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                '● EN DIRECT',
                                style: GoogleFonts.dmSans(
                                  color: _BattlePalette.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Battle du soir',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: _BattlePalette.textWhite,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Battle #${duel.id} • thème ${duel.sceneA.category}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: _BattlePalette.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BattleCard(
                                sideLabel: 'A',
                                borderColor: _BattlePalette.cyan,
                                accentColor: _BattlePalette.cyan,
                                scene: duel.sceneA,
                                percent: duel.percentA,
                                isSelected: duel.userVote == 0,
                                isLeading: duel.percentA >= duel.percentB,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _BattleCard(
                                sideLabel: 'B',
                                borderColor: _BattlePalette.yellow,
                                accentColor: _BattlePalette.yellow,
                                scene: duel.sceneB,
                                percent: duel.percentB,
                                isSelected: duel.userVote == 1,
                                isLeading: duel.percentB > duel.percentA,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'Qui a le mieux joué ?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: _BattlePalette.textWhite,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_formatCompactCount(duel.totalVotes)} votes comptabilisés',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: _BattlePalette.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: _VoteButton(
                                label: voted && duel.userVote == 0 ? 'A  Choisi' : 'A  Voter A',
                                background: _BattlePalette.cyan,
                                foreground: const Color(0xFF08111D),
                                enabled: !voted,
                                isSelected: duel.userVote == 0,
                                onTap: voted ? null : () => onVote(0),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _VoteButton(
                                label: voted && duel.userVote == 1 ? 'B  Choisi' : 'B  Voter B',
                                background: _BattlePalette.yellow,
                                foreground: const Color(0xFF1A1203),
                                enabled: !voted,
                                isSelected: duel.userVote == 1,
                                onTap: voted ? null : () => onVote(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _ResultPanel(
                          duel: duel,
                          voted: voted,
                        ),
                        const SizedBox(height: 24),
                        const _FooterGrid(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleCard extends StatelessWidget {
  const _BattleCard({
    required this.sideLabel,
    required this.borderColor,
    required this.accentColor,
    required this.scene,
    required this.percent,
    required this.isSelected,
    required this.isLeading,
  });

  final String sideLabel;
  final Color borderColor;
  final Color accentColor;
  final SceneModel scene;
  final double percent;
  final bool isSelected;
  final bool isLeading;

  @override
  Widget build(BuildContext context) {
    final badgeText = scene.author.scenesCount > 0
        ? '🔥 ${scene.author.scenesCount} scènes'
        : scene.category;

    return Container(
      height: 336,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 2.6),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isLeading ? 0.26 : 0.16),
            blurRadius: isLeading ? 24 : 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BattleSceneArtwork(scene: scene),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.76),
                  ],
                  stops: const [0.0, 0.35, 0.66, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  sideLabel,
                  style: GoogleFonts.dmSans(
                    color: _BattlePalette.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF07111D),
                    size: 22,
                  ),
                ),
              ),
            Positioned(
              left: 12,
              bottom: 74,
              child: Text(
                badgeText,
                style: GoogleFonts.dmSans(
                  color: accentColor == _BattlePalette.yellow
                      ? const Color(0xFFFFD36A)
                      : const Color(0xFF84EAFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: _BattlePalette.cardBottom.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _BattleAvatar(user: scene.author, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scene.author.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: _BattlePalette.textWhite,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${_formatCompactCount(scene.likesCount)} likes • ${(percent * 100).round()}%',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFCCD2E0),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF262C46),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF9299AB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.enabled,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool enabled;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || isSelected ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 78,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: background.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  color: foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.duel, required this.voted});

  final DuelModel duel;
  final bool voted;

  @override
  Widget build(BuildContext context) {
    final winnerIsA = duel.percentA >= duel.percentB;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _BattlePalette.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _BattlePalette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _BattlePalette.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: _BattlePalette.yellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voted ? 'Résultat provisoire' : 'Vote en direct',
                      style: GoogleFonts.dmSans(
                        color: _BattlePalette.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      voted
                          ? 'Ton vote est enregistré pour ${duel.userVote == 0 ? duel.sceneA.author.displayName : duel.sceneB.author.displayName}'
                          : 'Le leader actuel est ${winnerIsA ? duel.sceneA.author.displayName : duel.sceneB.author.displayName}',
                      style: GoogleFonts.dmSans(
                        color: _BattlePalette.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ResultLegend(
                  label: duel.sceneA.author.displayName,
                  value: '${(duel.percentA * 100).round()}%',
                  color: _BattlePalette.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultLegend(
                  label: duel.sceneB.author.displayName,
                  value: '${(duel.percentB * 100).round()}%',
                  color: _BattlePalette.yellow,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (duel.percentA * 1000).round(),
                    child: Container(color: _BattlePalette.cyan),
                  ),
                  Expanded(
                    flex: (duel.percentB * 1000).round(),
                    child: Container(color: _BattlePalette.yellow),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetaStat(
                  label: 'Scène A',
                  value: duel.sceneA.title,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetaStat(
                  label: 'Scène B',
                  value: duel.sceneB.title,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultLegend extends StatelessWidget {
  const _ResultLegend({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: _BattlePalette.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: _BattlePalette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetaStat extends StatelessWidget {
  const _MetaStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: _BattlePalette.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: GoogleFonts.dmSans(
            color: _BattlePalette.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _BattlePalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _BattlePalette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _BattlePalette.textWhite),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: _BattlePalette.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterGrid extends StatelessWidget {
  const _FooterGrid();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: _BattlePalette.divider, width: 1.2),
                  right: BorderSide(color: _BattlePalette.divider, width: 0.6),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: _BattlePalette.divider, width: 1.2),
                  left: BorderSide(color: _BattlePalette.divider, width: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleGlow extends StatelessWidget {
  const _BattleGlow({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: 80,
              spreadRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleSceneArtwork extends StatelessWidget {
  const _BattleSceneArtwork({required this.scene});

  final SceneModel scene;

  @override
  Widget build(BuildContext context) {
    final assetPath = _sceneAssetPathFor(scene.id);
    if (assetPath != null) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: _BattlePalette.cardBottom),
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.network(
      scene.thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: _BattlePalette.cardBottom),
    );
  }
}

class _BattleAvatar extends StatelessWidget {
  const _BattleAvatar({required this.user, required this.size});

  final UserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = _avatarAssetPathFor(user.id);
    if (assetPath == null) {
      return UserAvatar(url: user.avatarUrl, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _BattlePalette {
  static const background = Color(0xFF050816);
  static const cyan = Color(0xFF35D9FF);
  static const yellow = Color(0xFFF6B72E);
  static const red = Color(0xFFFF5C6A);
  static const textWhite = Color(0xFFF7F8FC);
  static const muted = Color(0xFF9AA3B2);
  static const cardBottom = Color(0xFF151B34);
  static const divider = Color(0xFF14192D);
  static const surface = Color(0xFF0E1327);
  static const panel = Color(0xFF0B1022);
}

String? _sceneAssetPathFor(String sceneId) {
  switch (sceneId) {
    case 's1':
      return 'assets/scenes/scene_rupture_telephone.svg';
    case 's2':
      return 'assets/scenes/scene_interrogatoire.svg';
    case 's3':
      return 'assets/scenes/scene_declaration_amour.svg';
    case 's4':
      return 'assets/scenes/scene_mauvaise_nouvelle.svg';
    case 's5':
      return 'assets/scenes/scene_confrontation.svg';
    default:
      return null;
  }
}

String? _avatarAssetPathFor(String userId) {
  switch (userId) {
    case 'u1':
      return 'assets/avatars/avatar_luna_act.svg';
    case 'u2':
      return 'assets/avatars/avatar_max_act.svg';
    case 'u3':
      return 'assets/avatars/avatar_neo_player.svg';
    case 'u4':
      return 'assets/avatars/avatar_clara_scene.svg';
    case 'u5':
      return 'assets/avatars/avatar_theo_drama.svg';
    case 'u6':
      return 'assets/avatars/avatar_act_queen.svg';
    case 'u7':
      return 'assets/avatars/avatar_victor_play.svg';
    default:
      return null;
  }
}

String _formatCompactCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}k';
  }
  return count.toString();
}
