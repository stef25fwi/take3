import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                  onVote: (choice) =>
                      ref.read(duelProvider.notifier).vote(choice),
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Body
// ──────────────────────────────────────────────────────────────────────────────

class _BattleBody extends StatefulWidget {
  const _BattleBody({required this.duel, required this.onVote});
  final DuelModel duel;
  final void Function(int) onVote;

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
    widget.onVote(choice);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    const hPad = AppThemeTokens.pageHorizontalPadding;
    final cardAreaW = screenW - hPad * 2;
    const cardGap = 12.0;
    final cardW = (cardAreaW - cardGap) / 2;
    // Card height: proportional, targeting ~46% of screen
    final cardH = (mq.size.height * 0.46).clamp(260.0, 400.0);
    final isDark = AppThemeTokens.isDark(context);

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
            child: Column(
              children: [
                const SizedBox(height: 8),
                // ── Cards ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    children: [
                      SizedBox(
                        width: cardW,
                        height: cardH,
                        child: _BattleCard(
                          sideLabel: 'A',
                          borderColor: _P.cyan,
                          glowColor: _P.cyan,
                          borderGradient: _P.cyanBorderGrad,
                          scene: widget.duel.sceneA,
                          metrics:
                              '${_fmtCount(widget.duel.sceneA.viewsCount)} vues • ${_fmtCount(widget.duel.sceneA.likesCount)} ♥',
                          isSelected: _selectedVote == 0,
                        ),
                      ),
                      const SizedBox(width: cardGap),
                      SizedBox(
                        width: cardW,
                        height: cardH,
                        child: _BattleCard(
                          sideLabel: 'B',
                          borderColor: _P.gold,
                          glowColor: _P.gold,
                          borderGradient: _P.goldBorderGrad,
                          scene: widget.duel.sceneB,
                          metrics:
                              '${_fmtCount(widget.duel.sceneB.viewsCount)} vues • ${_fmtCount(widget.duel.sceneB.likesCount)} ♥',
                          isSelected: _selectedVote == 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title ──
                Text(
                  'Qui a le mieux joué ?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppThemeTokens.primaryText(context),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Vote Buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    children: [
                      Expanded(
                        child: _VoteButton(
                          label: _selectedVote == 0 ? 'A  Choisi ✓' : 'A  Voter A',
                          gradient: _P.voteAGrad,
                          glowColor: _P.cyan,
                          textColor: const Color(0xFF06101E),
                          enabled: !_voteSubmitted,
                          isSelected: _selectedVote == 0,
                          onTap: () => _handleVote(0),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _VoteButton(
                          label: _selectedVote == 1 ? 'B  Choisi ✓' : 'B  Voter B',
                          gradient: _P.voteBGrad,
                          glowColor: _P.gold,
                          textColor: const Color(0xFF1A1203),
                          enabled: !_voteSubmitted,
                          isSelected: _selectedVote == 1,
                          onTap: () => _handleVote(1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer — dark empty zone as in the reference
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Battle Card
// ──────────────────────────────────────────────────────────────────────────────

class _BattleCard extends StatelessWidget {
  const _BattleCard({
    required this.sideLabel,
    required this.borderColor,
    required this.glowColor,
    required this.borderGradient,
    required this.scene,
    required this.metrics,
    required this.isSelected,
  });

  final String sideLabel;
  final Color borderColor;
  final Color glowColor;
  final Gradient borderGradient;
  final SceneModel scene;
  final String metrics;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    const outerR = 24.0;
    const bw = 2.5;
    const innerR = outerR - bw;
    const bannerH = 64.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerR),
        gradient: borderGradient,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.10),
            blurRadius: 44,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(bw),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerR),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail ──
            _SceneArtwork(scene: scene, side: sideLabel),

            // ── Dark vignette ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.40, 0.68, 1.0],
                ),
              ),
            ),

            // ── Side label badge ──
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  sideLabel,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // ── Selected check ──
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: borderColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF07111D),
                    size: 20,
                  ),
                ),
              ),

            // ── Bottom banner ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    height: bannerH,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111524).withValues(alpha: 0.88),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _Avatar(user: scene.author, size: 34, battleSide: sideLabel),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scene.author.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: _P.textWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                metrics,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFB8BFD0),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2134),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.5),
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
            height: 76,
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
                  child: Text(
                    widget.label,
                    style: GoogleFonts.dmSans(
                      color: widget.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
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

// ──────────────────────────────────────────────────────────────────────────────
// Scene Artwork
// ──────────────────────────────────────────────────────────────────────────────

class _SceneArtwork extends StatelessWidget {
  const _SceneArtwork({required this.scene, this.side = 'A'});
  final SceneModel scene;
  final String side;

  @override
  Widget build(BuildContext context) {
    // Use battle PNG photos first
    final battleAsset = side == 'A'
        ? 'assets/scenes/battle_player_a.png'
        : 'assets/scenes/battle_player_b.png';

    return Image.asset(
      battleAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        // Fallback: SVG scene asset
        final svgAsset = _sceneAssetFor(scene.id);
        if (svgAsset != null) {
          return DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF111524)),
            child: SvgPicture.asset(svgAsset, fit: BoxFit.cover),
          );
        }
        // Fallback: network thumbnail
        return Image.network(
          scene.thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF111524)),
        );
      },
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

  // Text
  static const textWhite = Color(0xFFF7F8FC);

  // Card border gradients
  static const cyanBorderGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF47D7FF),
      Color(0xFF3DCCFF),
      Color(0xFF5A9BFF),
    ],
  );

  static const goldBorderGrad = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFFFE168),
      Color(0xFFF2B33A),
      Color(0xFFFF9A42),
    ],
  );

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

// ──────────────────────────────────────────────────────────────────────────────
// Asset mappings
// ──────────────────────────────────────────────────────────────────────────────

String? _sceneAssetFor(String id) {
  switch (id) {
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

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}
