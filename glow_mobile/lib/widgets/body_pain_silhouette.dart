import 'package:flutter/material.dart';

import '../models/body_region.dart';

/// Tappable front/back silhouette; [painLevels] maps region id → 1–3.
class BodyPainSilhouette extends StatelessWidget {
  const BodyPainSilhouette({
    super.key,
    required this.backView,
    required this.painLevels,
    required this.onRegionTap,
    this.height = 420,
  });

  final bool backView;
  final Map<String, int> painLevels;
  final ValueChanged<String> onRegionTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          width: w,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final local = d.localPosition;
              final nx = (local.dx / w).clamp(0.0, 1.0);
              final ny = (local.dy / height).clamp(0.0, 1.0);
              for (final region in BodyRegions.forView(backView)) {
                if (region.rect.contains(Offset(nx, ny))) {
                  onRegionTap(region.id);
                  return;
                }
              }
            },
            child: CustomPaint(
              size: Size(w, height),
              painter: _BodyPainPainter(
                backView: backView,
                painLevels: painLevels,
                scheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BodyPainPainter extends CustomPainter {
  _BodyPainPainter({
    required this.backView,
    required this.painLevels,
    required this.scheme,
  });

  final bool backView;
  final Map<String, int> painLevels;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = scheme.surfaceContainerHighest.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = scheme.outline.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cx = size.width * 0.5;
    final headR = size.width * 0.11;
    final headCy = size.height * 0.07;

    canvas.drawOval(
      Rect.fromCircle(center: Offset(cx, headCy), radius: headR),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCircle(center: Offset(cx, headCy), radius: headR),
      outline,
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.12,
        size.width * 0.44,
        size.height * 0.36,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(torso, bodyPaint);
    canvas.drawRRect(torso, outline);

    for (final side in [-1.0, 1.0]) {
      final arm = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx + side * size.width * 0.22 - (side > 0 ? size.width * 0.14 : 0),
          size.height * 0.16,
          size.width * 0.12,
          size.height * 0.22,
        ),
        const Radius.circular(14),
      );
      canvas.drawRRect(arm, bodyPaint);
      canvas.drawRRect(arm, outline);
    }

    for (final side in [-1.0, 1.0]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx + side * size.width * 0.06 - (side > 0 ? size.width * 0.14 : 0),
          size.height * 0.46,
          size.width * 0.14,
          size.height * 0.48,
        ),
        const Radius.circular(16),
      );
      canvas.drawRRect(leg, bodyPaint);
      canvas.drawRRect(leg, outline);
    }

    for (final region in BodyRegions.forView(backView)) {
      final r = region.rect;
      final rect = Rect.fromLTWH(
        r.left * size.width,
        r.top * size.height,
        r.width * size.width,
        r.height * size.height,
      );
      final level = painLevels[region.id] ?? 0;
      final fill = _colorForLevel(level);
      final regionPaint = Paint()
        ..color = fill
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        regionPaint,
      );
      if (level > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()
            ..color = scheme.error.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  Color _colorForLevel(int level) {
    if (level <= 0) {
      return scheme.primary.withValues(alpha: 0.06);
    }
    final t = level / BodyPainLevel.severe;
    return Color.lerp(
          scheme.surfaceContainerHigh,
          scheme.error,
          0.25 + t * 0.65,
        ) ??
        scheme.error;
  }

  @override
  bool shouldRepaint(covariant _BodyPainPainter old) {
    return old.backView != backView ||
        old.painLevels != painLevels ||
        old.scheme != scheme;
  }
}
