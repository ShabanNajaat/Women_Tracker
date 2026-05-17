import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/glow_effects_service.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  /// When false, skips [BackdropFilter] for dense UI (calendars, long text).
  final bool useBackdropBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.useBackdropBlur = true,
  });

  static double _blurSigma(bool glassOn) {
    if (!glassOn) return 0;
    return kIsWeb ? 4 : 6;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlowEffectsService.instance.enabled,
      builder: (context, glassOn, _) {
        final scheme = Theme.of(context).colorScheme;
        final isDark = scheme.brightness == Brightness.dark;
        final sigma =
            (glassOn && useBackdropBlur && !isDark) ? _blurSigma(true) : 0.0;
        final fill = glassOn
            ? (isDark
                ? scheme.surfaceContainerHighest
                : scheme.surfaceContainerHighest.withValues(alpha: 0.42))
            : scheme.surfaceContainerHighest;
        final borderColor =
            scheme.outline.withValues(alpha: isDark ? (glassOn ? 0.22 : 0.28) : (glassOn ? 0.35 : 0.45));

        final inner = Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: child,
        );

        if (sigma <= 0) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: inner,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: inner,
          ),
        );
      },
    );
  }
}
