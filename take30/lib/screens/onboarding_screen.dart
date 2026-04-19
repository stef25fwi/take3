import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../theme/take30_screen_themes.dart';
import '../widgets/take30_logo.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T30Colors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Take30Logo(height: 52),
              ),
              const SizedBox(height: 28),
              const Expanded(
                child: _HeroCollagePlaceholder(),
              ),
              const SizedBox(height: 28),
              Text(
                'Rejoue des scènes\n& deviens viral',
                textAlign: TextAlign.center,
                style: T30Text.h1.copyWith(
                  fontSize: 32,
                  color: T30Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.03,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 18),
              Column(
                children: [
                  Text(
                    'Scènes quotidiennes',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duels',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classements',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Découverte de talents',
                    textAlign: TextAlign.center,
                    style: T30Text.bodyMedium.copyWith(
                      color: T30Colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRouter.auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: T30Colors.yellow,
                    shadowColor: const Color.fromRGBO(255, 184, 0, 0.22),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ).copyWith(
                    elevation: const WidgetStatePropertyAll(0),
                  ),
                  child: Text(
                    'Commencer',
                    style: T30Text.buttonPrimary.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: T30Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => context.go('${AppRouter.auth}?tab=login'),
                child: Text(
                  'Se connecter',
                  style: T30Text.bodyMedium.copyWith(
                    color: T30Colors.textSecondary,
                    fontSize: 15,
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

class _HeroCollagePlaceholder extends StatelessWidget {
  const _HeroCollagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = width * 0.44;
        final cardHeight = height * 0.72;

        return Stack(
          children: [
            Positioned(
              left: width * -0.01,
              top: height * 0.14,
              child: _PhotoSlot(
                width: cardWidth,
                height: cardHeight,
                imagePath: '../take 30 images IA/1pic.png',
                angle: -0.14,
              ),
            ),
            Positioned(
              left: width * 0.28,
              top: height * -0.01,
              child: _PhotoSlot(
                width: cardWidth * 1.03,
                height: cardHeight * 1.10,
                imagePath: '../take 30 images IA/2pic.png',
                angle: 0.02,
                highlighted: true,
              ),
            ),
            Positioned(
              right: width * -0.01,
              top: height * 0.15,
              child: _PhotoSlot(
                width: cardWidth,
                height: cardHeight,
                imagePath: '../take 30 images IA/3pic.png',
                angle: 0.15,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhotoSlot extends StatefulWidget {
  const _PhotoSlot({
    required this.width,
    required this.height,
    required this.imagePath,
    required this.angle,
    this.highlighted = false,
  });

  final double width;
  final double height;
  final String imagePath;
  final double angle;
  final bool highlighted;

  @override
  State<_PhotoSlot> createState() => _PhotoSlotState();
}

class _PhotoSlotState extends State<_PhotoSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderAnimation;

  @override
  void initState() {
    super.initState();
    _borderAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.highlighted ? 9000 : 12000),
    )..repeat();
  }

  @override
  void dispose() {
    _borderAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(28);
    final rainbowColors = widget.highlighted
        ? const [
            Color(0x66FF7A8A),
            Color(0x66FFC97A),
            Color(0x66FFF08A),
            Color(0x664FE0C4),
            Color(0x6657AEFF),
            Color(0x668E74FF),
            Color(0x66FF7A8A),
          ]
        : const [
            Color(0x4DFF8FA0),
            Color(0x4DFFC58E),
            Color(0x4DEAD98B),
            Color(0x4D67D9C5),
            Color(0x4D78B4FF),
            Color(0x4DA58BFF),
            Color(0x4DFF8FA0),
          ];

    return Transform.rotate(
      angle: widget.angle,
      child: AnimatedBuilder(
        animation: _borderAnimation,
        builder: (context, _) {
          final borderGlow = widget.highlighted
              ? const Color.fromRGBO(8, 16, 32, 0.34)
              : const Color.fromRGBO(8, 16, 32, 0.26);

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: borderGlow,
                  blurRadius: widget.highlighted ? 32 : 26,
                  offset: const Offset(0, 18),
                  spreadRadius: widget.highlighted ? 2 : 0,
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: SweepGradient(
                  startAngle: 0,
                  endAngle: math.pi * 2,
                  colors: rainbowColors,
                  transform: GradientRotation(
                    (_borderAnimation.value * math.pi * 2) +
                        (widget.highlighted ? 0.35 : 0),
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.highlighted ? 2.0 : 1.5),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: const Color(0xFF0D1626),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: widget.highlighted ? 0.08 : 0.05,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: borderRadius,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                widget.imagePath,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.06),
                                      Colors.transparent,
                                      const Color(0xCC081020),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xCC0D1626),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Text(
                            widget.highlighted
                                ? 'Scene star'
                                : 'Nouveau format',
                            textAlign: TextAlign.center,
                            style: T30Text.bodyMedium.copyWith(
                              color: T30Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
        },
      ),
    );
  }
}
