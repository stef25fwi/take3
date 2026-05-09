import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import 'shared_widgets.dart';

class Take60RecordCinematicHero extends StatefulWidget {
  const Take60RecordCinematicHero({
    super.key,
    required this.user,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final UserModel user;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  @override
  State<Take60RecordCinematicHero> createState() =>
      _Take60RecordCinematicHeroState();
}

class _Take60RecordCinematicHeroState extends State<Take60RecordCinematicHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.height < 850;
    final titleSize = media.width >= 412 ? 44.0 : 40.0;
    final subtitleSize = media.width >= 400 ? 17.0 : 16.0;
    final heroHeight = isCompact ? 392.0 : 430.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 1 + (_controller.value * 0.02);
        final glowMix = 0.22 + (_controller.value * 0.10);
        final spotlightIntensity = 0.98 + (_controller.value * 0.02);

        return Container(
          width: double.infinity,
          height: heroHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
              bottom: Radius.zero,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF070A12), Color(0xFF0A0D16), Color(0xFF05070D)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.45),
                blurRadius: 34,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFFF8A00).withValues(alpha: glowMix),
                        const Color(0xFFFAFCFF).withValues(alpha: 0.05),
                        const Color(0xFF008CFF).withValues(alpha: glowMix * 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -90,
                bottom: -120,
                child: _GlowOrb(
                  color: const Color(0xFFFF9E2B),
                  size: 330,
                  opacity: 0.33 + _controller.value * 0.12,
                ),
              ),
              Positioned(
                right: -84,
                top: -96,
                child: _GlowOrb(
                  color: const Color(0xFF29A2FF),
                  size: 340,
                  opacity: 0.28 + _controller.value * 0.10,
                ),
              ),
              Positioned(
                top: heroHeight * 0.17,
                left: (media.width / 2) - 100,
                child: _GlowOrb(
                  color: Colors.white,
                  size: 200,
                  opacity: 0.11,
                ),
              ),
              Positioned(
                right: -20,
                top: 62,
                child: _StudioSpotlightProp(
                  intensity: spotlightIntensity,
                ),
              ),
              Positioned(
                left: -26,
                bottom: -8,
                child: _CinemaCameraProp(
                  orangeGlow: 0.40 + _controller.value * 0.12,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.05),
                        radius: 1.10,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    children: [
                      const _ModeTournageBadge(),
                      const SizedBox(height: 26),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: media.width * 0.72,
                        ),
                        child: Text(
                          'Deviens\nl\'acteur principal.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.interTight(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.4,
                            height: 0.93,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Color.fromRGBO(0, 0, 0, 0.35),
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: media.width * 0.70,
                        ),
                        child: Text(
                          'Choisis une scene, regarde l\'intro IA,\npuis tourne ta performance en\n60 secondes.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.interTight(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w600,
                            height: 1.32,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Transform.scale(
                        scale: pulse,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 300,
                            minHeight: 58,
                          ),
                          child: _PrimaryCtaButton(
                            label: '🎬  Tourner ma video',
                            onTap: widget.onPrimaryTap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: _SecondaryCtaButton(
                          label: 'Voir les defis',
                          onTap: widget.onSecondaryTap,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _StatsRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeTournageBadge extends StatelessWidget {
  const _ModeTournageBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 190,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1D26), Color(0xFF0A0C12)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.35),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFF2D2D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(255, 45, 45, 0.70),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'MODE TOURNAGE',
              style: GoogleFonts.interTight(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCtaButton extends StatelessWidget {
  const _PrimaryCtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF8A00), Color(0xFFFF5E00)],
              ),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.28),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255, 120, 0, 0.45),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color.fromRGBO(255, 196, 0, 0.30),
                  blurRadius: 36,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.40),
                          Color.fromRGBO(255, 255, 255, 0.00),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Tourner ma video',
                    child: Text(
                      label,
                      style: GoogleFonts.interTight(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
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

class _SecondaryCtaButton extends StatelessWidget {
  const _SecondaryCtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: const Color.fromRGBO(255, 255, 255, 0.06),
          side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onTap,
        child: Semantics(
          button: true,
          label: 'Voir les defis',
          child: Text(
            label,
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 370;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.timer_outlined,
            iconColor: Color(0xFFFF9A2F),
            value: '60s',
            label: 'Duree max',
            isCompact: isCompact,
          ),
        ),
        _VerticalDividerStat(isCompact: isCompact),
        Expanded(
          child: _StatItem(
            icon: Icons.chat_bubble_outline,
            iconColor: Color(0xFF39B5FF),
            value: 'Intro IA',
            label: 'incluse',
            isCompact: isCompact,
          ),
        ),
        _VerticalDividerStat(isCompact: isCompact),
        Expanded(
          child: _StatItem(
            icon: Icons.menu_book_rounded,
            iconColor: Color(0xFFB07CFF),
            value: '3 plans',
            label: 'a jouer',
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }
}

class _VerticalDividerStat extends StatelessWidget {
  const _VerticalDividerStat({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: isCompact ? 28 : 34,
      color: Colors.white.withValues(alpha: 0.22),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isCompact,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromRGBO(0, 0, 0, 0.42),
            border: Border.all(color: iconColor.withValues(alpha: 0.72)),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.interTight(
            color: Colors.white,
            fontSize: isCompact ? 13 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.interTight(
            color: const Color(0xFFD7DCE8),
            fontSize: isCompact ? 9.5 : 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 0.6),
            blurRadius: size * 0.45,
            spreadRadius: size * 0.10,
          ),
        ],
      ),
    );
  }
}

class _StudioSpotlightProp extends StatelessWidget {
  const _StudioSpotlightProp({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 310,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 26,
            top: 0,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 90,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF151B28), Color(0xFF090D14)],
                  ),
                  border: Border.all(color: const Color(0xFF2F3D5C)),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF89D8FF),
                  size: 28,
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: 34,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 240,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF25A7FF)
                          .withValues(alpha: 0.36 * intensity),
                      const Color(0xFF0A57C7).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinemaCameraProp extends StatelessWidget {
  const _CinemaCameraProp({required this.orangeGlow});

  final double orangeGlow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 360,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 36,
            bottom: 0,
            child: Container(
              width: 8,
              height: 190,
              color: const Color(0xFF0E121C),
            ),
          ),
          Positioned(
            left: 76,
            bottom: 0,
            child: Container(
              width: 8,
              height: 178,
              color: const Color(0xFF0E121C),
            ),
          ),
          Positioned(
            left: 55,
            bottom: 170,
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                width: 180,
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A202D), Color(0xFF0A0E16)],
                  ),
                  border: Border.all(color: const Color(0xFF394156), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: orangeGlow),
                      blurRadius: 30,
                      offset: const Offset(-8, 10),
                    ),
                    const BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.45),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: const [
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Icon(Icons.videocam, color: Color(0xFFBFC8DB), size: 28),
                    ),
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Icon(Icons.tune, color: Color(0xFF7E8CA8), size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 186,
            bottom: 196,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF151C28), Color(0xFF05070D)],
                ),
                border: Border.all(color: const Color(0xFF5C6579), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(41, 162, 255, 0.20),
                    blurRadius: 14,
                    offset: Offset(4, -2),
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
