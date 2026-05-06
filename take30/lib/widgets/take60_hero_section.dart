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
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
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
                animation: _slide,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _slide.value,
                    child: child,
                  );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final heroWidth = constraints.maxWidth;
                    final metrics = _ResponsiveHeroMetrics.fromWidth(heroWidth);

                    return Container(
                      width: double.infinity,
                      height: metrics.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(metrics.radius),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.045),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.58),
                            blurRadius: 34,
                            spreadRadius: 0,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(metrics.radius),
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
                                    Color(0xFF0B1020),
                                    Color(0xFF060914),
                                    Color(0xFF020308),
                                  ],
                                  stops: [0.0, 0.48, 1.0],
                                ),
                              ),
                            ),
                            const _HeroGlow(),
                            Positioned(
                              top: 0,
                              right: 0,
                              bottom: 0,
                              width: heroWidth * 0.56,
                              child: _HeroImagePane(
                                imageProvider: widget.heroImageProvider,
                                radius: metrics.radius,
                              ),
                            ),
                            const Positioned.fill(child: _HeroOverlays()),
                            Positioned(
                              left: metrics.copyLeft,
                              top: metrics.copyTop,
                              bottom: metrics.copyBottom,
                              right: metrics.copyRight(heroWidth),
                              child: _HeroCopy(
                                metrics: metrics,
                                onNewVideoTap: widget.onNewVideoTap,
                                onChallengeTap: widget.onChallengeTap,
                              ),
                            ),
                            Positioned(
                              right: metrics.statsRight,
                              top: metrics.statsTop,
                              child: _HeroStatsColumn(
                                formatValue: widget.formatValue,
                                scenesValue: widget.scenesValue,
                                likesValue: widget.likesValue,
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

class _ResponsiveHeroMetrics {
  const _ResponsiveHeroMetrics._({
    required this.isMobile,
    required this.height,
    required this.radius,
    required this.titleSize,
    required this.subtitleSize,
    required this.copyLeft,
    required this.copyTop,
    required this.copyBottom,
    required this.mobileCopyRight,
    required this.desktopCopyRightFactor,
    required this.statsRight,
    required this.statsTop,
    required this.primaryButtonWidth,
    required this.secondaryButtonWidth,
    required this.buttonHeight,
  });

  factory _ResponsiveHeroMetrics.fromWidth(double width) {
    final isMobile = width < 600;
    final isTablet = width >= 600 && width <= 1024;
    final basePrimary = isMobile ? 190.0 : 204.0;
    final baseSecondary = isMobile ? 145.0 : 154.0;
    final copyWidth = isMobile ? width - 22 - 118 : width * 0.62 - 28;
    final availableButtonWidth = (copyWidth - 12).clamp(304.0, 9999.0);
    final buttonScale = (availableButtonWidth / (basePrimary + baseSecondary))
        .clamp(0.0, 1.0);

    return _ResponsiveHeroMetrics._(
      isMobile: isMobile,
      height: isMobile ? 252 : (isTablet ? 280 : 320),
      radius: isMobile ? 24 : (isTablet ? 28 : 30),
      titleSize: isMobile ? 30 : (isTablet ? 34 : 38),
      subtitleSize: isMobile ? 15 : (isTablet ? 16 : 17),
      copyLeft: isMobile ? 22 : 28,
      copyTop: isMobile ? 28 : 34,
      copyBottom: isMobile ? 24 : 26,
      mobileCopyRight: 118,
      desktopCopyRightFactor: 0.38,
      statsRight: isMobile ? 22 : 30,
      statsTop: isMobile ? 18 : 20,
      primaryButtonWidth: (basePrimary * buttonScale).clamp(172.0, basePrimary),
      secondaryButtonWidth:
          (baseSecondary * buttonScale).clamp(132.0, baseSecondary),
      buttonHeight: isMobile ? 48 : 50,
    );
  }

  final bool isMobile;
  final double height;
  final double radius;
  final double titleSize;
  final double subtitleSize;
  final double copyLeft;
  final double copyTop;
  final double copyBottom;
  final double mobileCopyRight;
  final double desktopCopyRightFactor;
  final double statsRight;
  final double statsTop;
  final double primaryButtonWidth;
  final double secondaryButtonWidth;
  final double buttonHeight;

  double copyRight(double heroWidth) {
    return isMobile ? mobileCopyRight : heroWidth * desktopCopyRightFactor;
  }
}

class _HeroImagePane extends StatelessWidget {
  const _HeroImagePane({
    required this.imageProvider,
    required this.radius,
  });

  final ImageProvider? imageProvider;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = imageProvider;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      ),
      child: image == null
          ? const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A120E),
                    Color(0xFF3D210E),
                    Color(0xFF100A10),
                    Color(0xFF030409),
                  ],
                  stops: [0.0, 0.36, 0.72, 1.0],
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

class _HeroOverlays extends StatelessWidget {
  const _HeroOverlays();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: const [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF070B16),
                  Color(0xE6070B16),
                  Color(0x66070B16),
                  Color(0x00070B16),
                ],
                stops: [0.0, 0.38, 0.62, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x99000000),
                ],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color(0x22000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: 190,
            width: 120,
            height: 120,
            child: _GlowCircle(
              color: const Color(0xFFFFD18A).withOpacity(0.18),
              blurRadius: 70,
            ),
          ),
          Positioned(
            top: 26,
            right: 128,
            width: 90,
            height: 90,
            child: _GlowCircle(
              color: const Color(0xFFFFA726).withOpacity(0.20),
              blurRadius: 60,
            ),
          ),
          Positioned(
            top: 76,
            right: 72,
            width: 150,
            height: 150,
            child: _GlowCircle(
              color: const Color(0xFFFF7A18).withOpacity(0.10),
              blurRadius: 90,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.color,
    required this.blurRadius,
  });

  final Color color;
  final double blurRadius;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
      child: DecoratedBox(
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
    required this.metrics,
    required this.onNewVideoTap,
    required this.onChallengeTap,
  });

  final _ResponsiveHeroMetrics metrics;
  final VoidCallback? onNewVideoTap;
  final VoidCallback? onChallengeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = constraints.maxWidth < 305
            ? metrics.titleSize.clamp(27.0, metrics.titleSize).toDouble()
            : metrics.titleSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Deviens',
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                height: 0.98,
                letterSpacing: -1.2,
                color: Colors.white,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                maxLines: 1,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'l’',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 0.98,
                        letterSpacing: -1.3,
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                    TextSpan(
                      text: 'acteur principal',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 0.98,
                        letterSpacing: -1.3,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Joue. Publie. Affronte. Deviens une légende.',
              maxLines: 2,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: metrics.subtitleSize,
                fontWeight: FontWeight.w600,
                height: 1.25,
                letterSpacing: -0.1,
                color: Colors.white.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroActionButton.primary(
                  width: metrics.primaryButtonWidth,
                  height: metrics.buttonHeight,
                  onTap: onNewVideoTap,
                ),
                const SizedBox(width: 12),
                _HeroActionButton.secondary(
                  width: metrics.secondaryButtonWidth,
                  height: metrics.buttonHeight,
                  onTap: onChallengeTap,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton.primary({
    required this.width,
    required this.height,
    required this.onTap,
  })  : label = 'Nouvelle vidéo',
        icon = Icons.videocam_rounded,
        iconSize = 20,
        iconColor = const Color(0xFF050505),
        textColor = const Color(0xFF050505),
        fontWeight = FontWeight.w800,
        backgroundColor = null,
        borderColor = null,
        gradient = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFC21A),
            Color(0xFFFFA000),
          ],
        ),
        shadowColor = const Color(0xFFFFB000);

  const _HeroActionButton.secondary({
    required this.width,
    required this.height,
    required this.onTap,
  })  : label = 'Voir le défi',
        icon = Icons.bolt_rounded,
        iconSize = 19,
        iconColor = const Color(0xFFEDEDED),
        textColor = Colors.white,
        fontWeight = FontWeight.w700,
        backgroundColor = const Color(0xE0151922),
        borderColor = const Color(0x1AFFFFFF),
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x22FFFFFF),
            Color(0x00111111),
          ],
        ),
        shadowColor = null;

  final double width;
  final double height;
  final VoidCallback? onTap;
  final String label;
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color textColor;
  final FontWeight fontWeight;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: shadowColor == null
              ? null
              : [
                  BoxShadow(
                    color: shadowColor!.withOpacity(0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: backgroundColor,
                gradient: gradient,
                borderRadius: BorderRadius.circular(28),
                border: borderColor == null
                    ? null
                    : Border.all(color: borderColor!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: iconColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: fontWeight,
                        letterSpacing: -0.1,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatsColumn extends StatelessWidget {
  const _HeroStatsColumn({
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
        _HeroStatCard(label: 'Format', value: formatValue),
        const SizedBox(height: 10),
        _HeroStatCard(label: 'Scènes', value: scenesValue),
        const SizedBox(height: 10),
        _HeroStatCard(label: 'Likes', value: likesValue),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 74,
          height: 65,
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xCC141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.075),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: Colors.white.withOpacity(0.66),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
