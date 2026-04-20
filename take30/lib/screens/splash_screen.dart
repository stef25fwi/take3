import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _bg = AppColors.navy;
  static const _text = Color(0xFFFFFFFF);
  static const _subtleGrey = Color(0xFF2A2A2E);
  static const _yellow = Color(0xFFF4C20D);

  late final AnimationController _master;
  late final AnimationController _shineController;

  late final Animation<double> _bgGlowOpacity;
  late final Animation<double> _takeOpacity;
  late final Animation<double> _takeScale;
  late final Animation<double> _takeBlurFade;

  late final Animation<double> _hourglassOpacity;
  late final Animation<double> _hourglassDrop;
  late final Animation<double> _hourglassRotation;
  late final Animation<double> _hourglassSettleScale;

  late final Animation<double> _sixtyOpacity;
  late final Animation<double> _sixtySlide;
  late final Animation<double> _sixtyScale;

  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlide;

  late final Animation<double> _wholeLogoScale;
  late final Animation<double> _wholeLogoOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _bgGlowOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.00, 0.24, curve: Curves.easeOut),
    );

    _takeOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
    );

    _takeScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.00, 0.24, curve: Curves.easeOutBack),
      ),
    );

    _takeBlurFade = Tween<double>(begin: 6, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
      ),
    );

    _hourglassOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.16, 0.34, curve: Curves.easeOut),
    );

    _hourglassDrop = Tween<double>(begin: -260, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.16, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _hourglassRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: (math.pi * 2) + 0.14,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 84,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: (math.pi * 2) + 0.14,
          end: math.pi * 2,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 16,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.20, 0.74, curve: Curves.linear),
      ),
    );

    _hourglassSettleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 0.985)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.985, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.56, 0.82, curve: Curves.easeOut),
      ),
    );

    _sixtyOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.58, 0.76, curve: Curves.easeOut),
    );

    _sixtySlide = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.58, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _sixtyScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.58, 0.80, curve: Curves.easeOutBack),
      ),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.76, 0.94, curve: Curves.easeOut),
    );

    _taglineSlide = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.76, 0.96, curve: Curves.easeOutCubic),
      ),
    );

    _wholeLogoScale = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.82, 1.0, curve: Curves.easeInOut),
      ),
    );

    _wholeLogoOpacity = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _master, curve: Curves.linear),
    );

    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        _goNext();
      }
    });

    unawaited(_master.forward());
    unawaited(_shineController.repeat(reverse: true));
  }

  Future<void> _goNext() async {
    _navigated = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }
    context.go(AppRouter.auth);
  }

  @override
  void dispose() {
    _master.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 380;

    final logoTextSize = isSmall ? 74.0 : 88.0;
    final hourglassHeight = logoTextSize;
    final leftTuck = -(logoTextSize * 0.22);
    final rightTuck = -(logoTextSize * 0.19);

    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_master, _shineController]),
        builder: (context, _) {
          return Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: _bg),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _bgGlowOpacity.value * 0.9,
                    child: CustomPaint(
                      painter: _AmbientGlowPainter(
                        glowShift: _shineController.value,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: _wholeLogoScale.value,
                          child: Opacity(
                            opacity: _wholeLogoOpacity.value,
                            child: RepaintBoundary(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    _AnimatedLogoText(
                                      text: 'TAKE',
                                      color: _text,
                                      fontSize: logoTextSize,
                                      opacity: _takeOpacity.value,
                                      scale: _takeScale.value,
                                      blur: _takeBlurFade.value,
                                    ),
                                    SizedBox(width: leftTuck),
                                    Opacity(
                                      opacity: _hourglassOpacity.value,
                                      child: Transform.translate(
                                        offset: Offset(
                                          0,
                                          _hourglassDrop.value +
                                              (logoTextSize * -0.015),
                                        ),
                                        child: Transform.rotate(
                                          angle: _hourglassRotation.value,
                                          child: Transform.scale(
                                            scale:
                                                _hourglassSettleScale.value,
                                            child: _PremiumHourglass(
                                              height: hourglassHeight,
                                              strokeColor: _text,
                                              sandColor: _yellow,
                                              innerGlow: 0.25 +
                                                  (_shineController.value *
                                                      0.10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: rightTuck),
                                    Opacity(
                                      opacity: _sixtyOpacity.value,
                                      child: Transform.translate(
                                        offset: Offset(_sixtySlide.value, 0),
                                        child: Transform.scale(
                                          scale: _sixtyScale.value,
                                          child: _StaticLogoText(
                                            text: '60',
                                            color: _text,
                                            fontSize: logoTextSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _taglineSlide.value),
                            child: const Text(
                              'Rejoue des scènes\n& deviens viral',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                                color: _text,
                                letterSpacing: -0.9,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: _taglineOpacity.value * 0.7,
                          child: Container(
                            width: 54,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _subtleGrey,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor:
                                  0.68 + (_shineController.value * 0.18),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _yellow,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedLogoText extends StatelessWidget {
  const _AnimatedLogoText({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.opacity,
    required this.scale,
    required this.blur,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double opacity;
  final double scale;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final shadowOpacity = (blur / 6).clamp(0.0, 1.0) * 0.08;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Text(
          text,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -3.2,
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: shadowOpacity),
                blurRadius: blur,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticLogoText extends StatelessWidget {
  const _StaticLogoText({
    required this.text,
    required this.color,
    required this.fontSize,
  });

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: -3.2,
        color: color,
      ),
    );
  }
}

class _PremiumHourglass extends StatelessWidget {
  const _PremiumHourglass({
    required this.height,
    required this.strokeColor,
    required this.sandColor,
    required this.innerGlow,
  });

  final double height;
  final Color strokeColor;
  final Color sandColor;
  final double innerGlow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.72,
      height: height,
      child: CustomPaint(
        painter: _PremiumHourglassPainter(
          strokeColor: strokeColor,
          sandColor: sandColor,
          innerGlow: innerGlow,
        ),
      ),
    );
  }
}

class _PremiumHourglassPainter extends CustomPainter {
  _PremiumHourglassPainter({
    required this.strokeColor,
    required this.sandColor,
    required this.innerGlow,
  });

  final Color strokeColor;
  final Color sandColor;
  final double innerGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..moveTo(size.width * 0.18, size.height * 0.06)
      ..lineTo(size.width * 0.82, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.18,
        size.width * 0.64,
        size.height * 0.39,
      )
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.47,
        size.width * 0.50,
        size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.53,
        size.width * 0.36,
        size.height * 0.61,
      )
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.82,
        size.width * 0.18,
        size.height * 0.94,
      )
      ..lineTo(size.width * 0.82, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.82,
        size.width * 0.64,
        size.height * 0.61,
      )
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.53,
        size.width * 0.50,
        size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.47,
        size.width * 0.36,
        size.height * 0.39,
      )
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.18,
        size.width * 0.18,
        size.height * 0.06,
      )
      ..close();

    final topSand = Path()
      ..moveTo(size.width * 0.26, size.height * 0.18)
      ..lineTo(size.width * 0.74, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.30,
        size.width * 0.55,
        size.height * 0.40,
      )
      ..lineTo(size.width * 0.45, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.30,
        size.width * 0.26,
        size.height * 0.18,
      )
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          sandColor.withValues(alpha: 0.95),
          sandColor,
          sandColor.withValues(alpha: 0.92),
        ],
      ).createShader(Offset.zero & size);

    final glowPaint = Paint()
      ..color = sandColor.withValues(alpha: innerGlow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final outlineShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.075;

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03;

    canvas.drawPath(topSand, glowPaint);
    canvas.drawPath(topSand, fillPaint);

    canvas.drawPath(outline, outlineShadowPaint);
    canvas.drawPath(outline, outlinePaint);

    final highlight = Path()
      ..moveTo(size.width * 0.26, size.height * 0.13)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.25,
        size.width * 0.34,
        size.height * 0.37,
      );

    canvas.drawPath(highlight, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _PremiumHourglassPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.sandColor != sandColor ||
        oldDelegate.innerGlow != innerGlow;
  }
}

class _AmbientGlowPainter extends CustomPainter {
  _AmbientGlowPainter({required this.glowShift});

  final double glowShift;

  @override
  void paint(Canvas canvas, Size size) {
    final center1 = Offset(
      size.width * 0.50,
      size.height * (0.48 + (glowShift - 0.5) * 0.02),
    );

    final rect1 = Rect.fromCircle(
      center: center1,
      radius: size.width * 0.22,
    );

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.10),
          const Color(0xFFFFD54F).withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect1);

    final center2 = Offset(
      size.width * 0.50,
      size.height * 0.44,
    );

    final rect2 = Rect.fromCircle(
      center: center2,
      radius: size.width * 0.34,
    );

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF).withValues(alpha: 0.08),
          const Color(0xFFFFFFFF).withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect2);

    canvas.drawRect(Offset.zero & size, Paint()..color = _SplashScreenState._bg);
    canvas.drawCircle(center2, size.width * 0.34, paint2);
    canvas.drawCircle(center1, size.width * 0.22, paint1);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) {
    return oldDelegate.glowShift != glowShift;
  }
}
