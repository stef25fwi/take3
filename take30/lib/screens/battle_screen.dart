import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────────────────────
// BATTLE SCREEN — Pixel Perfect (PRD)
// ──────────────────────────────────────────────────────────────────────────────

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duelProvider);
    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _P.gold),
            )
          : state.duel == null
              ? Center(
                  child: Text(
                    'Aucune battle disponible',
                    style: GoogleFonts.dmSans(
                      color: AppThemeTokens.primaryText(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : _BattleBody(
                  duel: state.duel!,
                  onVoteCandidateA: () =>
                    ref.read(duelProvider.notifier).vote(0),
                  onVoteCandidateB: () =>
                    ref.read(duelProvider.notifier).vote(1),
                  onShareCandidateA: () =>
                    ref.read(shareServiceProvider).shareScene(state.duel!.sceneA),
                  onShareCandidateB: () =>
                    ref.read(shareServiceProvider).shareScene(state.duel!.sceneB),
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Body
// ──────────────────────────────────────────────────────────────────────────────

class _BattleBody extends StatefulWidget {
  const _BattleBody({
    required this.duel,
    required this.onShareCandidateA,
    required this.onShareCandidateB,
    required this.onVoteCandidateA,
    required this.onVoteCandidateB,
  });
  final DuelModel duel;
  final VoidCallback onShareCandidateA;
  final VoidCallback onShareCandidateB;
  final VoidCallback onVoteCandidateA;
  final VoidCallback onVoteCandidateB;

  @override
  State<_BattleBody> createState() => _BattleBodyState();
}

class _BattleBodyState extends State<_BattleBody> {
  int? _selectedVote;
  bool _voteSubmitted = false;

  @override
  void initState() {
    super.initState();
    _selectedVote = widget.duel.userVote;
    _voteSubmitted = widget.duel.userVote != null;
  }

  @override
  void didUpdateWidget(covariant _BattleBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duel.userVote != oldWidget.duel.userVote) {
      _selectedVote = widget.duel.userVote;
      _voteSubmitted = widget.duel.userVote != null;
    }
  }

  void _handleVote(int choice) {
    if (_voteSubmitted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedVote = choice;
      _voteSubmitted = true;
    });
    if (choice == 0) {
      widget.onVoteCandidateA();
      return;
    }
    widget.onVoteCandidateB();
  }

  void onShareCandidateA() {
    HapticFeedback.selectionClick();
    widget.onShareCandidateA();
  }

  void onShareCandidateB() {
    HapticFeedback.selectionClick();
    widget.onShareCandidateB();
  }

  void onVoteCandidateA() => _handleVote(0);

  void onVoteCandidateB() => _handleVote(1);

  String _candidateName(SceneModel scene, String fallbackSide) {
    final displayName = scene.author.displayName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final username = scene.author.username.trim();
    if (username.isNotEmpty) {
      return username;
    }
    return fallbackSide;
  }

  String _voteLabel({
    required SceneModel scene,
    required String fallbackSide,
    required bool isSelected,
  }) {
    if (isSelected) {
      return 'Choisi ✓';
    }
    return 'Voter pour ${_candidateName(scene, fallbackSide)}';
  }

  String _shareLabel(SceneModel scene, String fallbackSide) {
    return 'Partager ${_candidateName(scene, fallbackSide)}';
  }

  String _battleRoundLabel() {
    final digits = widget.duel.id.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) {
      final shortDigits = digits.length > 2
          ? digits.substring(digits.length - 2)
          : digits.padLeft(2, '0');
      return 'Battle #$shortDigits';
    }
    return 'Battle en cours';
  }

  String _battleThemeLabel() {
    final category = widget.duel.sceneA.category.trim();
    if (category.isNotEmpty) {
      return category;
    }
    final title = widget.duel.sceneA.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    return 'Interprétation';
  }

  Duration _remainingTime() {
    final remaining = widget.duel.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int _participantCount() {
    final totalVotes = widget.duel.totalVotes;
    return totalVotes > 0 ? totalVotes : 2;
  }

  String _sideStatusLabel(int side) {
    if (_voteSubmitted && _selectedVote == side) {
      return 'voté';
    }
    if (_voteSubmitted) {
      return 'en lice';
    }
    return 'à départager';
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    const hPad = AppThemeTokens.pageHorizontalPadding;
    const cardGap = 12.0;
    final actionColumnW = (mq.size.width - hPad * 2 - cardGap) / 2;
    final isDark = AppThemeTokens.isDark(context);
    final remaining = _remainingTime();
    final isLive = widget.duel.status == 'active' && remaining > Duration.zero;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF070B1A),
                  Color(0xFF0A1023),
                  Color(0xFF0E1222),
                  Color(0xFF070B1A),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              )
            : AppThemeTokens.pageGradient(context),
      ),
      child: Stack(
        children: [
          // Subtle ambient glow top-left (cyan)
          const Positioned(
            top: -60,
            left: -40,
            child: _AmbientGlow(
              color: _P.cyan,
              size: 200,
              opacity: 0.08,
            ),
          ),
          // Subtle ambient glow right (gold)
          const Positioned(
            top: 200,
            right: -50,
            child: _AmbientGlow(
              color: _P.gold,
              size: 180,
              opacity: 0.06,
            ),
          ),

          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Battle',
                          style: GoogleFonts.dmSans(
                            color: AppThemeTokens.primaryText(context),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D6D).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFFF6B81).withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            '● EN DIRECT',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFFFF8BA0),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _BattleSummaryCard(
                    title: _battleRoundLabel(),
                    subtitle: 'Duel du soir • thème « ${_battleThemeLabel()} »',
                    participantsLabel:
                        '${_fmtCount(_participantCount())} participants',
                    remaining: remaining,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _BattleCompactCard(
                          user: widget.duel.sceneA.author,
                          sideLabel: 'A',
                          accentColor: _P.cyan,
                          scoreLabel: '${(widget.duel.percentA * 100).round()}%',
                          statusLabel: _sideStatusLabel(0),
                          isSelected: _selectedVote == 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BattleCompactCard(
                          user: widget.duel.sceneB.author,
                          sideLabel: 'B',
                          accentColor: _P.gold,
                          scoreLabel: '${(widget.duel.percentB * 100).round()}%',
                          statusLabel: _sideStatusLabel(1),
                          isSelected: _selectedVote == 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: actionColumnW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SecondaryBattleButton(
                              label: _shareLabel(widget.duel.sceneA, 'A'),
                              borderColor: _P.cyan,
                              glowColor: _P.cyan,
                              onTap: onShareCandidateA,
                            ),
                            const SizedBox(height: 12),
                            _VoteButton(
                              label: _voteLabel(
                                scene: widget.duel.sceneA,
                                fallbackSide: 'A',
                                isSelected: _selectedVote == 0,
                              ),
                              gradient: _P.voteAGrad,
                              glowColor: _P.cyan,
                              textColor: const Color(0xFF06101E),
                              enabled: !_voteSubmitted,
                              isSelected: _selectedVote == 0,
                              onTap: onVoteCandidateA,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: actionColumnW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SecondaryBattleButton(
                              label: _shareLabel(widget.duel.sceneB, 'B'),
                              borderColor: _P.gold,
                              glowColor: _P.gold,
                              onTap: onShareCandidateB,
                            ),
                            const SizedBox(height: 12),
                            _VoteButton(
                              label: _voteLabel(
                                scene: widget.duel.sceneB,
                                fallbackSide: 'B',
                                isSelected: _selectedVote == 1,
                              ),
                              gradient: _P.voteBGrad,
                              glowColor: _P.gold,
                              textColor: const Color(0xFF1A1203),
                              enabled: !_voteSubmitted,
                              isSelected: _selectedVote == 1,
                              onTap: onVoteCandidateB,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleSummaryCard extends StatelessWidget {
  const _BattleSummaryCard({
    required this.title,
    required this.subtitle,
    required this.participantsLabel,
    required this.remaining,
  });

  final String title;
  final String subtitle;
  final String participantsLabel;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141A2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: const Color(0xFFB8BFD0),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountdownBox(value: hours, unit: 'h'),
              const SizedBox(width: 10),
              _CountdownBox(value: minutes, unit: 'm'),
              const SizedBox(width: 10),
              _CountdownBox(value: seconds, unit: 's'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            participantsLabel,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.unit});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1321),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.dmSans(
              color: const Color(0xFFB8BFD0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleCompactCard extends StatelessWidget {
  const _BattleCompactCard({
    required this.user,
    required this.sideLabel,
    required this.accentColor,
    required this.scoreLabel,
    required this.statusLabel,
    required this.isSelected,
  });

  final UserModel user;
  final String sideLabel;
  final Color accentColor;
  final String scoreLabel;
  final String statusLabel;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141A2B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? accentColor.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.08),
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isSelected ? 0.16 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _Avatar(user: user, size: 56, battleSide: sideLabel),
          const SizedBox(height: 10),
          Text(
            user.displayName.trim().isEmpty ? sideLabel : user.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scoreLabel,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusLabel,
            style: GoogleFonts.dmSans(
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Vote Button
// ──────────────────────────────────────────────────────────────────────────────

class _VoteButton extends StatefulWidget {
  const _VoteButton({
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.textColor,
    required this.enabled,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Gradient gradient;
  final Color glowColor;
  final Color textColor;
  final bool enabled;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    if (!widget.enabled) return;
    widget.onTap();
  }

  void _onTapCancel() {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = !widget.enabled && !widget.isSelected;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: widget.gradient,
              border: Border.all(
                color: Colors.white
                    .withValues(alpha: widget.isSelected ? 0.40 : 0.18),
                width: widget.isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor
                      .withValues(alpha: widget.isSelected ? 0.45 : 0.30),
                  blurRadius: widget.isSelected ? 30 : 22,
                  spreadRadius: widget.isSelected ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top highlight
                Positioned(
                  top: 0,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.26),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: widget.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBattleButton extends StatelessWidget {
  const _SecondaryBattleButton({
    required this.label,
    required this.borderColor,
    required this.glowColor,
    required this.onTap,
  });

  final String label;
  final Color borderColor;
  final Color glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              borderColor.withValues(alpha: 0.20),
              const Color(0xFF141A2B),
              const Color(0xFF101625),
            ],
          ),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.60),
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.share_outlined,
                color: Colors.white.withValues(alpha: 0.95),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Avatar
// ──────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size, this.battleSide});
  final UserModel user;
  final double size;
  final String? battleSide;

  @override
  Widget build(BuildContext context) {
    // Try battle photo first for banner avatars
    final battleAsset = battleSide == 'A'
        ? 'assets/scenes/battle_player_a.png'
        : battleSide == 'B'
            ? 'assets/scenes/battle_player_b.png'
            : null;
    final asset = battleAsset ?? avatarPhotoAssetForUserId(user.id);
    if (asset != null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: ClipOval(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            cacheWidth: (size * 2).round(),
            cacheHeight: (size * 2).round(),
            errorBuilder: (_, __, ___) => UserAvatar(
              url: user.avatarUrl,
              userId: user.id,
              size: size,
            ),
          ),
        ),
      );
    }
    return UserAvatar(url: user.avatarUrl, userId: user.id, size: size);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Ambient Glow
// ──────────────────────────────────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
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
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Palette — PRD pixel-perfect colors
// ──────────────────────────────────────────────────────────────────────────────

class _P {
  // Backgrounds
  // Accent
  static const cyan = Color(0xFF47D7FF);
  static const gold = Color(0xFFF2B33A);

  // Vote button gradients
  static const voteAGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF79F4FF),
      Color(0xFF3DCCFF),
      Color(0xFF1AB6FF),
      Color(0xFF4E7CFF),
    ],
    stops: [0.0, 0.35, 0.68, 1.0],
  );

  static const voteBGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF07A),
      Color(0xFFF8BC2C),
      Color(0xFFFF9A2F),
      Color(0xFFFF7A1A),
    ],
    stops: [0.0, 0.34, 0.7, 1.0],
  );
}

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}
