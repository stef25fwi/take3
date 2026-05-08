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
                    Positioned(
                      left: metrics.contentLeft,
                      top: metrics.contentTop,
                      bottom: metrics.contentBottom,
                      right: metrics.contentRight,
                      child: _HeroContent(
                        metrics: metrics,
                        onNewVideoTap: widget.onNewVideoTap,
                        formatValue: widget.formatValue,
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
      contentRight: isMobile ? 24 : 32,
      titleSize: isMobile ? 28 : (isTablet ? 32 : 36),
      subtitleSize: isMobile ? 15 : 16,
      buttonHeight: isMobile ? 48 : 52,
      primaryButtonWidth: isMobile ? 188 : 208,
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

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.metrics,
    required this.onNewVideoTap,
    required this.formatValue,
  });

  final _HeroMetrics metrics;
  final VoidCallback? onNewVideoTap;
  final String formatValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = constraints.maxWidth < 240
            ? metrics.titleSize.clamp(24.0, metrics.titleSize).toDouble()
            : metrics.titleSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Prêt à tourner\nune performance ?',
                maxLines: 2,
                style: GoogleFonts.dmSans(
                  color: Colors.black,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: metrics.isMobile ? 225 : 360),
              child: Text(
                'Joue. Publie. Affronte. Deviens une légende.',
                maxLines: 2,
                style: GoogleFonts.dmSans(
                  color: Colors.black.withValues(alpha: 0.78),
                  fontSize: metrics.subtitleSize,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _HeroButton.primary(
                  label: 'Nouvelle vidéo',
                  width: metrics.primaryButtonWidth,
                  height: metrics.buttonHeight,
                  onTap: onNewVideoTap,
                ),
                _HeroFormatChip(
                  height: metrics.buttonHeight,
                  value: formatValue,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeroFormatChip extends StatelessWidget {
  const _HeroFormatChip({required this.height, required this.value});

  final double height;
  final String value;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xAA111111),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Format',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
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

  final String label;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool isPrimary;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
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

