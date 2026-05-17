import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/animated_glass_card.dart';
import '../widgets/glass_card.dart';
import 'wellness_library_screen.dart';

/// “Glow Space” — calm corner / blue-purple themed wellness space (roadmap).
class GlowSpaceScreen extends StatelessWidget {
  const GlowSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Icon(LucideIcons.orbit, color: scheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Glow Space',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A softer, low-noise corner for breathwork, evening wind-down, and lavender-lit focus.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedGlassCard(
              index: 0,
              child: GlassCard(
                useBackdropBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tonight',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placeholder: guided audio, starfield visuals, and gentle reminders will live here.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  scheme.surfaceContainerHighest,
                                  scheme.surface,
                                  scheme.primary.withValues(alpha: 0.3),
                                ]
                              : [
                                  const Color(0xFFFF9EC4).withValues(alpha: 0.5),
                                  scheme.surfaceContainerHigh,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const SizedBox(height: 120, width: double.infinity),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const WellnessLibraryScreen()),
                        );
                      },
                      icon: Icon(Icons.menu_book_rounded, color: scheme.onPrimary),
                      label: Text(
                        'Browse wellness library',
                        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
