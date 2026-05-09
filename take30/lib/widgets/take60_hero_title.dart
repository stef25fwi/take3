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
        final lineSize = compact ? 39.0 : 43.0;
        final performanceSize = compact ? 37.0 : 42.0;
        final brushHeight = compact ? 50.0 : 56.0;

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
            padding: const EdgeInsets.only(left: 20, top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Prêt à tourner', style: lineStyle),
                const SizedBox(height: 2),
                SizedBox(
                  height: brushHeight + 4,
                  width: math.min(
                    constraints.maxWidth - 20,
                    brushWidth + 8,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -4,
                        top: 2,
                        child: SizedBox(
                          width: brushWidth,
                          height: brushHeight,
                          child: Transform.rotate(
                            angle: -0.01,
                            child: CustomPaint(
                              painter: OrangeBrushPainter(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 4,
                        child: Transform.translate(
                          offset: const Offset(0, -1),
                          child: Text(
                            'une performance',
                            style: performanceStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
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
      ..moveTo(0, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.08,
        size.width * 0.42,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.22,
        size.width,
        size.height * 0.18,
      )
      ..lineTo(size.width, size.height * 0.74)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.88,
        size.width * 0.44,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.78,
        0,
        size.height * 0.64,
      )
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
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.24);
    final reliefPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.12,
        size.width * 0.94,
        size.height * 0.24,
      );
    canvas.drawPath(reliefPath, relief);

    final lowRelief = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x44B54800);
    final lowReliefPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.66)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.86,
        size.width * 0.94,
        size.height * 0.68,
      );
    canvas.drawPath(lowReliefPath, lowRelief);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}