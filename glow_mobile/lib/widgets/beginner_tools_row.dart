import 'package:flutter/material.dart';

import '../screens/app_guide_screen.dart';
import '../screens/exercise_timer_screen.dart';
import 'animated_glass_card.dart';
import 'glass_card.dart';
import 'glowie_mascot.dart';

/// Home shortcuts: Glowie guide + exercise timer.
class BeginnerToolsRow extends StatelessWidget {
  const BeginnerToolsRow({super.key, this.startIndex = 7});

  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const GlowieMascot(size: 36, animate: true),
            const SizedBox(width: 10),
            Text(
              'Help & cute tools',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AnimatedGlassCard(
                index: startIndex,
                child: _ToolTile(
                  emoji: '📖',
                  label: 'Glow guide',
                  subtitle: 'AI, AMA & every feature',
                  gradient: [
                    scheme.primary.withValues(alpha: 0.2),
                    scheme.tertiary.withValues(alpha: 0.15),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AppGuideScreen()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedGlassCard(
                index: startIndex + 1,
                child: _ToolTile(
                  emoji: '⏱️',
                  label: 'Workout timer',
                  subtitle: '30s squats · beep!',
                  gradient: [
                    scheme.tertiary.withValues(alpha: 0.22),
                    scheme.secondary.withValues(alpha: 0.14),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ExerciseTimerScreen()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      useBackdropBlur: false,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
