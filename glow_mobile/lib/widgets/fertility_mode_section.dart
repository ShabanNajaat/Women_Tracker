import 'package:flutter/material.dart';

import '../models/fertility_intent.dart';
import '../services/cycle_service.dart';

/// Settings control for Track / TTC / Avoid pregnancy framing.
class FertilityModeSection extends StatelessWidget {
  const FertilityModeSection({super.key, required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CycleService.instance,
      builder: (context, _) {
        final cycle = CycleService.instance;
        final intent = cycle.fertilityIntent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<FertilityIntent>(
              segments: [
                ButtonSegment(
                  value: FertilityIntent.track,
                  label: Text(FertilityIntent.track.shortLabel),
                  icon: const Icon(Icons.water_drop_outlined, size: 18),
                ),
                ButtonSegment(
                  value: FertilityIntent.ttc,
                  label: Text(FertilityIntent.ttc.shortLabel),
                  icon: const Icon(Icons.favorite_outline, size: 18),
                ),
                ButtonSegment(
                  value: FertilityIntent.avoidPregnancy,
                  label: Text(FertilityIntent.avoidPregnancy.shortLabel),
                  icon: const Icon(Icons.shield_outlined, size: 18),
                ),
              ],
              selected: {intent},
              onSelectionChanged: (s) => cycle.setFertilityIntent(s.first),
            ),
            const SizedBox(height: 12),
            Text(
              intent.settingsDescription,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              intent.calendarDisclaimer,
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
