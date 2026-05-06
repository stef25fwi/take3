import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class Take60HeroSection extends StatefulWidget {
  const Take60HeroSection({
    super.key,
    this.heroImageProvider,
    this.onNewVideoTap,
    this.onChallengeTap,
    this.formatValue = '60s',
    this.scenesValue = '0',
    this.likesValue = '0',
  });

  final ImageProvider? heroImageProvider;
  final VoidCallback? onNewVideoTap;
  final VoidCallback? onChallengeTap;
  final String formatValue;
  final String scenesValue;
  final String likesValue;

  @override
  State<Take60HeroSection> createState() => _Take60HeroSectionState();
}

class _Take60HeroSectionState extends State<Take60HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _offset = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: FadeTransition(
              opacity: _opacity,
              child: AnimatedBuilder(
                animation: _offset,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _offset.value,
                    child: child,
                  );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isMobile = width < 600;
                    final isTablet = width >= 600 && width < 1024;
                    final height = isMobile ? 250.0 : (isTablet ? 280.0 : 320.0);
                    final titleSize = isMobile ? 26.0 : (isTablet ? 30.0 : 34.0);
                    final subtitleSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
                    final rightZoneFactor = isMobile ? 0.48 : 0.50;

                    return Container(
                      width: double.infinity,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withValues(alpha: 0.55),
                            blurRadius: 30,
                            spreadRadius: 0,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0A1020),
                                    Color(0xFF050816),
                                    Color(0xFF000000),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              bottom: 0,
                              width: width * rightZoneFactor,
                              child: _HeroImagePane(
                                imageProvider: widget.heroImageProvider,
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        const Color(0xFF050816).withValues(alpha: 0.92),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: _BokehLights(compact: isMobile),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: width,
                              child: _HeroCopy(
                                titleSize: titleSize,
                                subtitleSize: subtitleSize,
                                onNewVideoTap: widget.onNewVideoTap,
                                onChallengeTap: widget.onChallengeTap,
                                compact: isMobile,
                              ),
                            ),
                            Positioned(
                              right: 22,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _StatsColumn(
                                  formatValue: widget.formatValue,
                                  scenesValue: widget.scenesValue,
                                  likesValue: widget.likesValue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImagePane extends StatelessWidget {
  const _HeroImagePane({required this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final image = imageProvider;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: image == null
          ? const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF20120A),
                    Color(0xFF3A1E0D),
                    Color(0xFF06070D),
                  ],
                ),
              ),
            )
          : Image(
              image: image,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
    );
  }
}

class _BokehLights extends StatelessWidget {
  const _BokehLights({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: compact ? 92 : 150,
            top: compact ? 34 : 54,
            child: _BlurCircle(
              size: compact ? 112 : 150,
              color: const Color(0xFFFFC56B).withValues(alpha: 0.12),
              blur: compact ? 42 : 54,
            ),
          ),
          Positioned(
            right: compact ? 42 : 86,
            top: compact ? 62 : 86,
            child: _BlurCircle(
              size: compact ? 88 : 120,
              color: const Color(0xFFFFA726).withValues(alpha: 0.18),
              blur: compact ? 36 : 48,
            ),
          ),
          Positioned(
            right: compact ? 116 : 196,
            top: compact ? 102 : 138,
            child: _BlurCircle(
              size: compact ? 68 : 96,
              color: const Color(0xFFFFE0A3).withValues(alpha: 0.22),
              blur: compact ? 30 : 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({
    required this.size,
    required this.color,
    required this.blur,
  });

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.titleSize,
    required this.subtitleSize,
    required this.onNewVideoTap,
    required this.onChallengeTap,
    required this.compact,
  });

  final double titleSize;
  final double subtitleSize;
  final VoidCallback? onNewVideoTap;
  final VoidCallback? onChallengeTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 20, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final reservedStatsWidth = compact ? 92.0 : 118.0;
          final readableWidth = math.max(
            220.0,
            constraints.maxWidth - reservedStatsWidth,
          );
          final buttonScale = math.min(
            1.0,
            (readableWidth - 12) / (176 + 154),
          );
          final primaryWidth = (compact ? 176.0 : 190.0) * buttonScale;
          final secondaryWidth = (compact ? 154.0 : 166.0) * buttonScale;

          return SizedBox(
            width: readableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Deviens',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    letterSpacing: -1.1,
                    color: Colors.white,
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFFFFD54F),
                        Color(0xFFFFA000),
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'l’acteur principal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Joue. Publie. Affronte. Deviens une légende.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _HeroButton.primary(
                      width: primaryWidth,
                      onTap: onNewVideoTap,
                    ),
                    const SizedBox(width: 12),
                    _HeroButton.secondary(
                      width: secondaryWidth,
                      onTap: onChallengeTap,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton.primary({
    required this.width,
    required this.onTap,
  })  : label = 'Nouvelle vidéo',
        icon = Icons.videocam_rounded,
        iconColor = Colors.black,
        textColor = Colors.black,
        fontWeight = FontWeight.w700,
        background = null,
        borderColor = null,
        gradient = const LinearGradient(
          colors: [
            Color(0xFFFFC107),
            Color(0xFFFFA000),
          ],
        ),
        shadowColor = const Color(0xFFFFB300);

  const _HeroButton.secondary({
    required this.width,
    required this.onTap,
  })  : label = 'Voir le défi',
        icon = Icons.bolt_rounded,
        iconColor = const Color(0xFFE5E7EB),
        textColor = Colors.white,
        fontWeight = FontWeight.w600,
        background = const Color(0xFF111827),
        borderColor = const Color(0x14FFFFFF),
        gradient = null,
        shadowColor = null;

  final double width;
  final VoidCallback? onTap;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final FontWeight fontWeight;
  final Color? background;
  final Color? borderColor;
  final Gradient? gradient;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              gradient: gradient,
              borderRadius: BorderRadius.circular(30),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!, width: 1),
              boxShadow: shadowColor == null
                  ? null
                  : [
                      BoxShadow(
                        color: shadowColor!.withValues(alpha: 0.38),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: fontWeight,
                      color: textColor,
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

class _StatsColumn extends StatelessWidget {
  const _StatsColumn({
    required this.formatValue,
    required this.scenesValue,
    required this.likesValue,
  });

  final String formatValue;
  final String scenesValue;
  final String likesValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatCard(label: 'Format', value: formatValue),
        const SizedBox(height: 10),
        _StatCard(label: 'Scènes', value: scenesValue),
        const SizedBox(height: 10),
        _StatCard(label: 'Likes', value: likesValue),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 74,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xCC111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
