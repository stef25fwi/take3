import 'package:flutter/material.dart';

class BattleOutlinedText extends StatelessWidget {
  const BattleOutlinedText(
    this.data, {
    super.key,
    required this.style,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final TextStyle style;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          data,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(
          data,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: style.copyWith(color: fillColor),
        ),
      ],
    );
  }
}