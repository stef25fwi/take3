import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String _heroExplorerLightAsset = '../take 30 images IA/heroexplorer.png';
const String _heroExplorerDarkAsset = '../take 30 images IA/heroexplorerblack.png';

class Take60CinematicHero extends StatefulWidget {
  const Take60CinematicHero({
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
  State<Take60CinematicHero> createState() => _Take60CinematicHeroState();
}

class Take60HeroSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Take60CinematicHero(
      heroImageProvider: heroImageProvider,
      onNewVideoTap: onNewVideoTap,
      onChallengeTap: onChallengeTap,
      formatValue: formatValue,
      scenesValue: scenesValue,
      likesValue: likesValue,
    );
  }
}

class _Take60CinematicHeroState extends State<Take60CinematicHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.055),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _HeroMetrics.fromWidth(constraints.maxWidth);

        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Container(
              height: metrics.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(metrics.radius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(metrics.radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: _HeroImageLayer(
                        imageProvider: widget.heroImageProvider,
                      ),
                    ),
                    Positioned.fill(
                      child: _HeroGradientMask(metrics: metrics),
                    ),
                    const Positioned.fill(child: _HeroBottomMask()),
                    Positioned(
                      left: metrics.contentLeft,
                      top: metrics.contentTop,
                      bottom: metrics.contentBottom,
                      right: metrics.contentRight,
                      child: _HeroContent(
                        metrics: metrics,
                        onNewVideoTap: widget.onNewVideoTap,
                        onChallengeTap: widget.onChallengeTap,
                      ),
                    ),
                    Positioned(
                      top: metrics.statsTop,
                      right: metrics.statsRight,
                      child: _HeroStatsColumn(
                        metrics: metrics,
                        formatValue: widget.formatValue,
                        scenesValue: widget.scenesValue,
                        likesValue: widget.likesValue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroMetrics {
  const _HeroMetrics({
    required this.isMobile,
    required this.height,
    required this.radius,
    required this.contentLeft,
    required this.contentTop,
    required this.contentBottom,
    required this.contentRight,
    required this.titleSize,
    required this.subtitleSize,
    required this.buttonHeight,
    required this.primaryButtonWidth,
    required this.secondaryButtonWidth,
    required this.statsTop,
    required this.statsRight,
    required this.statsWidth,
  });

  factory _HeroMetrics.fromWidth(double width) {
    final isMobile = width < 640;
    final isTablet = width >= 640 && width < 1024;
    return _HeroMetrics(
      isMobile: isMobile,
      height: isMobile ? 292 : (isTablet ? 316 : 340),
      radius: isMobile ? 28 : 32,
      contentLeft: isMobile ? 24 : 32,
      contentTop: isMobile ? 28 : 34,
      contentBottom: isMobile ? 24 : 28,
      contentRight: isMobile ? 126 : (isTablet ? 268 : 360),
      titleSize: isMobile ? 30 : (isTablet ? 36 : 40),
      subtitleSize: isMobile ? 15 : 16,
      buttonHeight: isMobile ? 48 : 52,
      primaryButtonWidth: isMobile ? 188 : 208,
      secondaryButtonWidth: isMobile ? 146 : 158,
      statsTop: isMobile ? 18 : 24,
      statsRight: isMobile ? 18 : 24,
      statsWidth: isMobile ? 76 : 82,
    );
  }

  final bool isMobile;
  final double height;
  final double radius;
  final double contentLeft;
  final double contentTop;
  final double contentBottom;
  final double contentRight;
  final double titleSize;
  final double subtitleSize;
  final double buttonHeight;
  final double primaryButtonWidth;
  final double secondaryButtonWidth;
  final double statsTop;
  final double statsRight;
  final double statsWidth;
}

class _HeroImageLayer extends StatelessWidget {
  const _HeroImageLayer({
    required this.imageProvider,
  });

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final image = imageProvider ??
        AssetImage(
          brightness == Brightness.dark
              ? _heroExplorerDarkAsset
              : _heroExplorerLightAsset,
        );

    return Image(
      image: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: brightness == Brightness.dark
                  ? const [
                      Color(0xFF080A12),
                      Color(0xFF111827),
                      Color(0xFF020308),
                    ]
                  : const [
                      Color(0xFFFFF7ED),
                      Color(0xFFFFE4B5),
                      Color(0xFF1F2937),
                    ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroGradientMask extends StatelessWidget {
  const _HeroGradientMask({required this.metrics});

  final _HeroMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? const <Color>[
                    Color(0xD9000000),
                    Color(0xAA000000),
                    Color(0x5C000000),
                    Colors.transparent,
                  ]
                : const <Color>[
                    Color(0x9A000000),
                    Color(0x66000000),
                    Color(0x22000000),
                    Colors.transparent,
                  ],
            stops: [0.0, metrics.isMobile ? 0.42 : 0.48, 0.72, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HeroBottomMask extends StatelessWidget {
  const _HeroBottomMask();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0x5C000000),
            ],
            stops: [0.52, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.metrics,
    required this.onNewVideoTap,
    required this.onChallengeTap,
  });

  final _HeroMetrics metrics;
  final VoidCallback? onNewVideoTap;
  final VoidCallback? onChallengeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = constraints.maxWidth < 210
            ? metrics.titleSize.clamp(27.0, metrics.titleSize).toDouble()
            : metrics.titleSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Spacer(),
            Text(
              'Deviens',
              maxLines: 1,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                height: 0.95,
                letterSpacing: -1.5,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.visible,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'l’acteur',
                      style: GoogleFonts.dmSans(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                        letterSpacing: -1.5,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFFD24A),
                              Color(0xFFFFA81F),
                              Color(0xFFFF7A18),
                            ],
                          ).createShader(
                            Rect.fromLTWH(0, 0, titleSize * 4.2, titleSize),
                          ),
                      ),
                    ),
                    TextSpan(
                      text: ' principal',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: metrics.isMobile ? 225 : 360),
              child: Text(
                'Joue. Publie. Affronte. Deviens une légende.',
                maxLines: 2,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: metrics.subtitleSize,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _HeroButton.primary(
                  label: 'Nouvelle vidéo',
                  width: metrics.primaryButtonWidth,
                  height: metrics.buttonHeight,
                  onTap: onNewVideoTap,
                ),
                _HeroButton.secondary(
                  label: 'Voir le défi',
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

class _HeroButton extends StatelessWidget {
  const _HeroButton.primary({
    required this.label,
    required this.width,
    required this.height,
    required this.onTap,
  })  : isPrimary = true,
        icon = Icons.videocam_rounded;

  const _HeroButton.secondary({
    required this.label,
    required this.width,
    required this.height,
    required this.onTap,
  })  : isPrimary = false,
        icon = Icons.bolt_rounded;

  final String label;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool isPrimary;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(999);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB547).withValues(alpha: 0.26),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: isPrimary
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFFFC640),
                          Color(0xFFFFA81F),
                        ],
                      )
                    : null,
                color: isPrimary ? null : const Color(0x29141922),
                border: isPrimary
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: isPrimary ? const Color(0xFF0B0B0B) : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color:
                            isPrimary ? const Color(0xFF0B0B0B) : Colors.white,
                        fontSize: 15,
                        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: -0.2,
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
    required this.metrics,
    required this.formatValue,
    required this.scenesValue,
    required this.likesValue,
  });

  final _HeroMetrics metrics;
  final String formatValue;
  final String scenesValue;
  final String likesValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroStatCard(metrics: metrics, label: 'Format', value: formatValue),
        const SizedBox(height: 10),
        _HeroStatCard(metrics: metrics, label: 'Scènes', value: scenesValue),
        const SizedBox(height: 10),
        _HeroStatCard(metrics: metrics, label: 'Likes', value: likesValue),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.metrics,
    required this.label,
    required this.value,
  });

  final _HeroMetrics metrics;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: metrics.statsWidth,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xAA111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: metrics.isMobile ? 23 : 25,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}