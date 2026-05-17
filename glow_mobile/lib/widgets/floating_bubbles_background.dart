import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/glow_tokens.dart';

/// Drifting bubbles with a gentle pop-in / pop-out pulse.
class FloatingBubblesBackground extends StatefulWidget {
  const FloatingBubblesBackground({
    super.key,
    required this.isLight,
    this.opacityScale = 1.0,
    this.baseGradient,
    this.bubbleSeed = 42,
    this.cute = false,
  });

  final bool isLight;
  final double opacityScale;
  final Gradient? baseGradient;
  final int bubbleSeed;

  /// Smaller, softer bubbles for in-app screens (dashboard, chat, etc.).
  final bool cute;

  @override
  State<FloatingBubblesBackground> createState() => _FloatingBubblesBackgroundState();
}

class _BubbleSpec {
  const _BubbleSpec({
    required this.anchorX,
    required this.anchorY,
    required this.baseRadius,
    required this.color,
    required this.opacity,
    required this.driftX,
    required this.driftY,
    required this.speed,
    required this.phase,
    required this.popPhase,
    required this.popSpeed,
  });

  final double anchorX;
  final double anchorY;
  final double baseRadius;
  final Color color;
  final double opacity;
  final double driftX;
  final double driftY;
  final double speed;
  final double phase;
  final double popPhase;
  final double popSpeed;
}

class _FloatingBubblesBackgroundState extends State<FloatingBubblesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_BubbleSpec> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
    _bubbles = _buildBubbles();
  }

  @override
  void didUpdateWidget(FloatingBubblesBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLight != widget.isLight ||
        oldWidget.opacityScale != widget.opacityScale ||
        oldWidget.bubbleSeed != widget.bubbleSeed ||
        oldWidget.cute != widget.cute) {
      _bubbles = _buildBubbles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_BubbleSpec> _buildBubbles() {
    final isLight = widget.isLight;
    final scale = widget.opacityScale;
    final cute = widget.cute;
    final rng = math.Random(widget.bubbleSeed);
    final count = cute ? 20 : 16;

    final palette = isLight
        ? [
            GlowTokens.rose.withValues(alpha: 0.85),
            const Color(0xFFFFC4D6),
            GlowTokens.lavender.withValues(alpha: 0.9),
            const Color(0xFFFFE0EC),
            GlowTokens.blushSage.withValues(alpha: 0.75),
            const Color(0xFFF8D4E8),
          ]
        : [
            GlowTokens.rose,
            const Color(0xFFFF9EC4),
            const Color(0xFFE895B5),
            GlowTokens.lavender.withValues(alpha: 0.85),
            const Color(0xFFCE6B9A),
            const Color(0xFFFFB8D0),
          ];

    final minR = cute ? 10.0 : 18.0;
    final maxR = cute ? 38.0 : 72.0;

    return List.generate(count, (i) {
      final color = palette[i % palette.length];
      final baseOpacity = (isLight ? 0.18 + rng.nextDouble() * 0.22 : 0.06 + rng.nextDouble() * 0.12) * scale;
      return _BubbleSpec(
        anchorX: rng.nextDouble(),
        anchorY: rng.nextDouble(),
        baseRadius: minR + rng.nextDouble() * (maxR - minR),
        color: color,
        opacity: baseOpacity,
        driftX: 0.03 + rng.nextDouble() * (cute ? 0.09 : 0.11),
        driftY: 0.04 + rng.nextDouble() * (cute ? 0.1 : 0.13),
        speed: 0.3 + rng.nextDouble() * 0.7,
        phase: rng.nextDouble() * math.pi * 2,
        popPhase: rng.nextDouble() * math.pi * 2,
        popSpeed: 0.9 + rng.nextDouble() * 1.6,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.baseGradient ??
                (widget.isLight ? _lightBaseGradient : GlowTokens.darkLoginBackdrop),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _BubblesPainter(
                  t: _controller.value * math.pi * 2,
                  bubbles: _bubbles,
                  isLight: widget.isLight,
                  cute: widget.cute,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        if (!widget.isLight)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const Gradient _lightBaseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      GlowTokens.creamSurface,
      Color(0xFFFFF5F9),
      Color(0xFFFFEEF5),
      Color(0xFFFFF8FB),
    ],
    stops: [0.0, 0.35, 0.68, 1.0],
  );
}

class _BubblesPainter extends CustomPainter {
  _BubblesPainter({
    required this.t,
    required this.bubbles,
    required this.isLight,
    required this.cute,
  });

  final double t;
  final List<_BubbleSpec> bubbles;
  final bool isLight;
  final bool cute;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final x = (b.anchorX + math.sin(t * b.speed + b.phase) * b.driftX).clamp(0.0, 1.0) * size.width;
      final y = (b.anchorY + math.cos(t * b.speed * 0.82 + b.phase * 1.3) * b.driftY).clamp(0.0, 1.0) *
          size.height;
      final center = Offset(x, y);

      // Pop in / pop out: scale breathes between ~55% and 100%.
      final popWave = 0.5 + 0.5 * math.sin(t * b.popSpeed + b.popPhase);
      final popScale = cute ? (0.55 + 0.45 * popWave) : (0.65 + 0.35 * popWave);
      final r = b.baseRadius * popScale;

      final coreAlpha = b.opacity * (0.85 + 0.15 * popWave);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withValues(alpha: coreAlpha),
            b.color.withValues(alpha: coreAlpha * 0.4),
            b.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);

      if (!isLight || cute) {
        final glowAlpha = coreAlpha * (isLight ? 0.35 : 0.22);
        final glow = Paint()
          ..shader = RadialGradient(
            colors: [
              b.color.withValues(alpha: glowAlpha),
              b.color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r * 1.45));
        canvas.drawCircle(center, r * 1.45, glow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => oldDelegate.t != t;
}
