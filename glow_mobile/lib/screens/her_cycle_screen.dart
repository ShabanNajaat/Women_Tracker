import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/cycle_wheel.dart';
import '../services/cycle_service.dart';
import '../widgets/glass_card.dart';
import 'ai_forecast_screen.dart';

/// Her Cycle — phase education & self-care (calendar lives in its own tab).
class HerCycleScreen extends StatefulWidget {
  const HerCycleScreen({super.key});

  @override
  State<HerCycleScreen> createState() => _HerCycleScreenState();
}

class _HerCycleScreenState extends State<HerCycleScreen> {
  @override
  void initState() {
    super.initState();
    CycleService.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CycleService.instance,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final cycle = CycleService.instance;
        final day = cycle.demoDayInCycle;
        final len = cycle.demoCycleLength;
        final phase = cycle.phaseForDay(day, cycleLength: len);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.refreshCw,
                        color: scheme.primary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Her Cycle',
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
                  'Cycle literacy and gentle self-care ideas — your month view and predictions stay in the Calendar tab.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: CycleWheel(
                    currentDay: day,
                    totalDays: len,
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  useBackdropBlur: false,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                    title: Text(
                      'AI forecast',
                      style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
                    ),
                    subtitle: Text(
                      'See your next period window, 21-day phase timeline, and mood patterns.',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const AiForecastScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where you are today',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cycle.hasCycleAnchor
                            ? cycle.usesPersonalizedPrediction
                                ? 'About day $day of your learned $len-day rhythm (${cycle.learning.validIntervals.length} cycles logged) — ${phase.displayName} phase.'
                                : 'About day $day of a $len-day pattern — log more period starts in Calendar to personalize.'
                            : 'Log your last period start in the Calendar tab once — then this card can anchor phases to your rhythm.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        phase.displayName,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                  Text(
                    phase.description,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (cycle.modeSpecificPhaseTip(phase) != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      cycle.modeSpecificPhaseTip(phase)!,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
                const SizedBox(height: 16),
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiny self-care menu',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _careBullet(scheme,
                          'Warm drink, unhurried meal, or snack with protein when you can.'),
                      _careBullet(scheme,
                          'Five minutes of slow breathing or stretching — no performance needed.'),
                      _careBullet(scheme,
                          'Send one honest check-in to yourself in the Journal tab.'),
                      _careBullet(scheme,
                          'If something feels new or frightening in your body, a clinician is the right next step.'),
                      const SizedBox(height: 14),
                      Text(
                        'Swipe to Calendar in the bottom bar when you want dates, logging, and estimates.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why this tab exists',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Glow separates “what day is it?” planning from “how do I care for this phase?” learning. '
                        'That way Her Cycle stays about meaning and care — not a second calendar.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _careBullet(ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_outline_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
