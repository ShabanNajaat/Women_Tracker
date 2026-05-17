import '../models/cycle_phase.dart';
import '../models/personalized_cycle_insight.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';

/// AI-style cycle insights from your last cycles (on-device, not medical advice).
abstract final class PersonalizedCycleInsightsService {
  static List<PersonalizedCycleInsight> build({
    required CycleService cycle,
    required HealthLogService health,
    int lookbackDays = 120,
  }) {
    final insights = <PersonalizedCycleInsight>[];
    final learning = cycle.learning;
    final intervals = learning.validIntervals;

    if (intervals.length >= 2) {
      final recent = intervals.length >= 3 ? intervals.sublist(intervals.length - 3) : intervals;
      final avgRecent = recent.reduce((a, b) => a + b) / recent.length;
      final avgAll = intervals.reduce((a, b) => a + b) / intervals.length;
      final lutealRecent = recent.map((len) => _estimateLutealDays(len)).toList();
      final lutealAvg = lutealRecent.reduce((a, b) => a + b) / lutealRecent.length;
      const typicalLuteal = 14;

      if (lutealAvg < typicalLuteal - 1.5) {
        insights.add(
          PersonalizedCycleInsight(
            headline: 'Your luteal phase may be shorter than average',
            detail:
                'Based on your last ${recent.length} logged cycles (avg ~${avgRecent.round()} days), '
                'your luteal window looks ~${lutealAvg.toStringAsFixed(0)} days vs a typical ~$typicalLuteal. '
                'You might feel the shift sooner — lighter workouts and steady protein can help.',
            actionHint: 'Try gentler strength sessions and earlier dinners in the week before your period.',
          ),
        );
      } else if (lutealAvg > typicalLuteal + 1.5) {
        insights.add(
          PersonalizedCycleInsight(
            headline: 'A longer luteal phase shows up in your logs',
            detail:
                'Your recent cycles suggest a longer luteal stretch (~${lutealAvg.toStringAsFixed(0)} days). '
                'PMS symptoms may linger — plan extra rest and magnesium-rich snacks.',
            actionHint: 'Schedule buffer days before your period for lower-intensity movement.',
          ),
        );
      }

      if ((avgRecent - avgAll).abs() >= 3 && intervals.length >= 3) {
        insights.add(
          PersonalizedCycleInsight(
            headline: 'Your cycle length is shifting lately',
            detail:
                'Last ${recent.length} cycles average ~${avgRecent.round()} days vs your overall ~${avgAll.round()} days. '
                'Stress, sleep, and travel can nudge timing — keep logging to refine predictions.',
            actionHint: 'Use the AI forecast screen to see updated period windows.',
          ),
        );
      }
    }

    final series = health.rangeEnding(DateTime.now(), lookbackDays);
    final lutealPain = <double>[];
    final follicularEnergy = <double>[];
    for (final (dateKey, log) in series) {
      final parts = dateKey.split('-');
      if (parts.length != 3) continue;
      try {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final day = cycle.dayInCycleFor(d);
        if (day == null) continue;
        final phase = cycle.phaseForDay(day, cycleLength: cycle.typicalCycleLength);
        if (log.pain > 0 && phase == CyclePhase.luteal) lutealPain.add(log.pain.toDouble());
        if (log.energy > 0 && phase == CyclePhase.follicular) follicularEnergy.add(log.energy.toDouble());
      } catch (_) {}
    }

    if (lutealPain.length >= 4) {
      final avg = lutealPain.reduce((a, b) => a + b) / lutealPain.length;
      if (avg >= 3) {
        insights.add(
          PersonalizedCycleInsight(
            headline: 'Higher pain in your luteal phase',
            detail:
                'Across ${lutealPain.length} luteal check-ins, pain averages ~${avg.toStringAsFixed(1)}/5. '
                'Heat, gentle movement, and hydration before your period may ease the build-up.',
            actionHint: 'Log body zones on the pain map to spot where discomfort clusters.',
          ),
        );
      }
    }

    if (follicularEnergy.length >= 4) {
      final avg = follicularEnergy.reduce((a, b) => a + b) / follicularEnergy.length;
      if (avg >= 3.5) {
        insights.add(
          PersonalizedCycleInsight(
            headline: 'Your energy peaks in follicular phase',
            detail:
                'Follicular days average ~${avg.toStringAsFixed(1)}/5 energy — great window for harder workouts '
                'and creative projects. Fuel with protein and complex carbs.',
            actionHint: 'Stack important tasks in the week after your period when you feel best.',
          ),
        );
      }
    }

    if (insights.isEmpty && cycle.hasCycleAnchor) {
      insights.add(
        const PersonalizedCycleInsight(
          headline: 'Keep logging to unlock deeper insights',
          detail:
              'Log period starts on the calendar and check in on mood, pain, and symptoms for a few weeks. '
              'We\'ll compare phases across your last cycles automatically.',
          actionHint: 'Aim for 3+ complete cycles logged for high-confidence personalization.',
        ),
      );
    }

    return insights.take(5).toList();
  }

  static int _estimateLutealDays(int cycleLength) {
    const defaultLuteal = 14;
    if (cycleLength <= defaultLuteal + 5) return (cycleLength * 0.45).round().clamp(8, 16);
    return defaultLuteal;
  }
}
