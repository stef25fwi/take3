import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/assets.dart';

class Take30Logo extends StatelessWidget {
  const Take30Logo({
    super.key,
    this.height = 44,
    this.assetPath = Take30Assets.logoDark,
    this.semanticLabel = 'Take 60',
  });

  final double height;
  final String assetPath;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: semanticLabel,
    );
  }
}
