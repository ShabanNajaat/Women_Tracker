import 'package:flutter/material.dart';

import '../theme/glow_tokens.dart';
import 'floating_bubbles_background.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isLight
          ? [
              GlowTokens.creamSurface,
              Color.lerp(GlowTokens.creamSurface, const Color(0xFFFFE8F2), 0.35)!,
              scheme.surfaceContainer,
            ]
          : [
              scheme.surface,
              scheme.surfaceContainerLow,
            ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        FloatingBubblesBackground(
          isLight: isLight,
          opacityScale: isLight ? 0.62 : 0.48,
          baseGradient: baseGradient,
          bubbleSeed: 17,
          cute: true,
        ),
        child,
      ],
    );
  }
}
