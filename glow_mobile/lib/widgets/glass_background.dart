import 'package:flutter/material.dart';
import '../theme/glow_tokens.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  scheme.surface,
                  const Color(0xFF141018),
                ]
              : [
                  scheme.surface,
                  scheme.surfaceContainerLow,
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlowTokens.lavender.withValues(alpha: isDark ? 0.12 : 0.2),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
