import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Take60HeroTitle extends StatelessWidget {
  const Take60HeroTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final lineSize = compact ? 42.0 : 46.0;
        final performanceSize = compact ? 40.0 : 45.0;
        final brushHeight = compact ? 58.0 : 62.0;

        final lineStyle = GoogleFonts.inter(
          fontSize: lineSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -2.4,
          height: 0.95,
          color: const Color(0xFF050505),
        );

        final performanceStyle = GoogleFonts.inter(
          fontSize: performanceSize,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -2.2,
          height: 1,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Color(0x88000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
            Shadow(
              color: Color(0x55FF8A00),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        );

        final textPainter = TextPainter(
          text: TextSpan(text: 'une performance', style: performanceStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        final performanceWidth = textPainter.width;
        final brushWidth = performanceWidth + 54;

        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: double.infinity,
            color: Colors.transparent,
            padding: const EdgeInsets.only(left: 28, top: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Prêt à tourner', style: lineStyle),
                const SizedBox(height: 4),
                SizedBox(
                  height: brushHeight + 4,
                  width: math.min(
                    constraints.maxWidth - 28,
                    brushWidth + 12,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -8,
                        top: 2,
                        child: SizedBox(
                          width: brushWidth,
                          height: brushHeight,
                          child: Transform.rotate(
                            angle: -0.022,
                            child: CustomPaint(
                              painter: OrangeBrushPainter(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 6,
                        child: Transform.translate(
                          offset: const Offset(0, -2),
                          child: Text(
                            'une performance',
                            style: performanceStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('qui marque ?', style: lineStyle),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OrangeBrushPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(2, size.height * 0.36)
      ..lineTo(16, size.height * 0.12)
      ..quadraticBezierTo(size.width * 0.08, -6, size.width * 0.18, 10)
      ..lineTo(size.width * 0.24, 4)
      ..lineTo(size.width * 0.31, 12)
      ..quadraticBezierTo(size.width * 0.41, -4, size.width * 0.54, 7)
      ..lineTo(size.width * 0.61, 3)
      ..lineTo(size.width * 0.7, 12)
      ..quadraticBezierTo(size.width * 0.79, 17, size.width * 0.86, 8)
      ..lineTo(size.width - 26, 12)
      ..lineTo(size.width - 10, size.height * 0.16)
      ..lineTo(size.width + 6, size.height * 0.24)
      ..lineTo(size.width - 2, size.height * 0.35)
      ..lineTo(size.width + 12, size.height * 0.44)
      ..lineTo(size.width - 3, size.height * 0.54)
      ..lineTo(size.width + 10, size.height * 0.63)
      ..lineTo(size.width - 7, size.height * 0.72)
      ..lineTo(size.width - 18, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.8, size.height + 10,
          size.width * 0.64, size.height - 1)
      ..lineTo(size.width * 0.58, size.height + 4)
      ..quadraticBezierTo(size.width * 0.45, size.height + 10,
          size.width * 0.29, size.height - 1)
      ..lineTo(size.width * 0.2, size.height + 4)
      ..quadraticBezierTo(size.width * 0.1, size.height + 2, 16,
          size.height - 10)
      ..lineTo(6, size.height * 0.76)
      ..lineTo(14, size.height * 0.62)
      ..lineTo(0, size.height * 0.48)
      ..close();

    canvas.drawShadow(path, const Color(0x88FF8A00), 34, false);
    canvas.drawShadow(
      path.shift(const Offset(0, 3)),
      const Color(0x55FF6F00),
      24,
      false,
    );

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFC107),
          Color(0xFFFF9800),
          Color(0xFFFF6F00),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);

    final hotCore = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x66FFF3C4),
          Color(0x22FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path.shift(const Offset(0, -1.5)), hotCore);

    final relief = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.3);
    final reliefPath = Path()
      ..moveTo(size.width * 0.07, size.height * 0.23)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * -0.02,
        size.width * 0.66,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.83,
        size.height * 0.22,
        size.width * 0.96,
        size.height * 0.14,
      );
    canvas.drawPath(reliefPath, relief);

    final lowRelief = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x55B54800);
    final lowReliefPath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.94,
        size.width * 0.88,
        size.height * 0.72,
      );
    canvas.drawPath(lowReliefPath, lowRelief);

    final dryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final random = math.Random(60);
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.18 + (i * 0.085));
      final startX = size.width * (0.06 + random.nextDouble() * 0.16);
      final endX = size.width * (0.76 + random.nextDouble() * 0.16);
      dryPaint
        ..strokeWidth = 1 + random.nextDouble() * 1.8
        ..color = Colors.white.withValues(
          alpha: 0.08 + random.nextDouble() * 0.1,
        );
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y + random.nextDouble() * 3 - 1.5),
        dryPaint,
      );
    }

    final tearPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x26B54800);
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.74 + (i * 0.08));
      canvas.drawLine(
        Offset(x, size.height * 0.18),
        Offset(x + 10, size.height * (0.7 - i * 0.08)),
        tearPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}