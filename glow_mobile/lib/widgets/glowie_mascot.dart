import 'package:flutter/material.dart';

/// Cute Glow guide mascot — soft blob face with optional gentle bounce.
class GlowieMascot extends StatefulWidget {
  const GlowieMascot({
    super.key,
    this.size = 64,
    this.animate = true,
    this.showSparkle = true,
  });

  final double size;
  final bool animate;
  final bool showSparkle;

  @override
  State<GlowieMascot> createState() => _GlowieMascotState();
}

class _GlowieMascotState extends State<GlowieMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _bounce = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = widget.size;

    Widget face = _Face(size: s, scheme: scheme, showSparkle: widget.showSparkle);

    if (!widget.animate) return SizedBox(width: s, height: s, child: face);

    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: SizedBox(width: s, height: s, child: face),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.size,
    required this.scheme,
    required this.showSparkle,
  });

  final double size;
  final ColorScheme scheme;
  final bool showSparkle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.45),
                scheme.tertiary.withValues(alpha: 0.65),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        Positioned(
          left: size * 0.18,
          top: size * 0.52,
          child: _blush(scheme),
        ),
        Positioned(
          right: size * 0.18,
          top: size * 0.52,
          child: _blush(scheme),
        ),
        Positioned(
          top: size * 0.3,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _eye(size, scheme),
              SizedBox(width: size * 0.14),
              _eye(size, scheme),
            ],
          ),
        ),
        Positioned(
          bottom: size * 0.26,
          child: Container(
            width: size * 0.24,
            height: size * 0.11,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        if (showSparkle)
          Positioned(
            top: size * 0.06,
            right: size * 0.04,
            child: Text('✨', style: TextStyle(fontSize: size * 0.22)),
          ),
      ],
    );
  }

  Widget _blush(ColorScheme scheme) {
    return Container(
      width: size * 0.14,
      height: size * 0.08,
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _eye(double size, ColorScheme scheme) {
    return Container(
      width: size * 0.1,
      height: size * 0.12,
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
