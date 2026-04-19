import 'package:flutter/material.dart';

import '../utils/assets.dart';

class Take30Logo extends StatelessWidget {
  const Take30Logo({
    super.key,
    this.height = 44,
    this.assetPath = Take30Assets.logoDark,
    this.semanticLabel = 'Take 60',
    this.color = Colors.white,
    this.sandColor = const Color(0xFFF4C20D),
    this.innerGlow = 0.25,
  });

  final double height;
  final String assetPath;
  final String semanticLabel;
  final Color color;
  final Color sandColor;
  final double innerGlow;

  @override
  Widget build(BuildContext context) {
    final fontSize = height;
    final leftTuck = -(fontSize * 0.22);
    final rightTuck = -(fontSize * 0.19);

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LogoText(
                text: 'TAKE',
                fontSize: fontSize,
                color: color,
              ),
              SizedBox(width: leftTuck),
              _PremiumHourglass(
                height: fontSize,
                strokeColor: color,
                sandColor: sandColor,
                innerGlow: innerGlow,
              ),
              SizedBox(width: rightTuck),
              _LogoText(
                text: '60',
                fontSize: fontSize,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoText extends StatelessWidget {
  const _LogoText({
    required this.text,
    required this.fontSize,
    required this.color,
  });

  final String text;
  final double fontSize;
  final Color color;

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
