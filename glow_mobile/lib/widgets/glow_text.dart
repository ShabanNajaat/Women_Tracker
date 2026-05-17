import 'package:flutter/material.dart';

class GlowText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;

  const GlowText(
    this.text, {
    super.key,
    this.style,
    this.colors = const [Colors.white, Color(0xFFB8A2D6)],
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}
