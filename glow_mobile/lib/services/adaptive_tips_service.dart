import '../models/adaptive_tip.dart';
import '../models/correlation_insight.dart';
import '../models/cycle_phase.dart';
import 'correlation_engine.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';

/// Tips that evolve from symptoms, phase, and correlation patterns.
abstract final class AdaptiveTipsService {
  static List<AdaptiveTip> generate({
    required HealthLogService health,
    required CycleService cycle,
    int lookbackDays = 60,
  }) {
    final tips = <AdaptiveTip>[];
    final series = health.rangeEnding(DateTime.now(), lookbackDays);
    final symptomCounts = <String, int>{};
    var highPainDays = 0;
    var lowMoodDays = 0;
    var lowWaterMenstrual = 0;
    var menstrualDays = 0;

    for (final (dateKey, log) in series) {
      for (final s in log.symptoms) {
        symptomCounts[s.toLowerCase()] = (symptomCounts[s.toLowerCase()] ?? 0) + 1;
      }
      if (log.pain >= 4) highPainDays++;
      if (log.mood > 0 && log.mood <= 2) lowMoodDays++;

      final parts = dateKey.split('-');
      if (parts.length != 3) continue;
      try {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final day = cycle.dayInCycleFor(d);
        if (day == null) continue;
        final phase = cycle.phaseForDay(day, cycleLength: cycle.typicalCycleLength);
        if (phase == CyclePhase.menstrual) {
          menstrualDays++;
          if (log.waterGlasses > 0 && log.waterGlasses < 4) lowWaterMenstrual++;
        }
      } catch (_) {}
    }

    final cramps = _countSymptom(symptomCounts, ['cramp', 'cramps', 'period pain']);
    if (cramps >= 2) {
      tips.add(
        AdaptiveTip(
          title: 'You often log cramps',
          body:
              'Cramps showed up $cramps times recently. A heating pad, magnesium-rich foods, and '
              'gentle walks may help — track what works in your journal.',
          category: 'Symptom-adaptive',
          iconName: 'healing',
        ),
      );
    }

    final anxiety = _countSymptom(symptomCounts, ['anxiety', 'anxious', 'stress', 'worried']);
    if (anxiety >= 2) {
      tips.add(
        AdaptiveTip(
          title: 'Stress & anxiety patterns',
          body:
              'You\'ve tagged stress/anxiety $anxiety times. Try 4-7-8 breathing for 2 minutes before bed, '
              'especially in your luteal phase when mood can dip.',
          category: 'Symptom-adaptive',
          iconName: 'spa',
        ),
      );
    }

    final bloating = _countSymptom(symptomCounts, ['bloat', 'bloating']);
    if (bloating >= 2) {
      tips.add(
        AdaptiveTip(
          title: 'Bloating relief ideas',
          body:
              'Bloating logged $bloating times — smaller meals, peppermint tea, and lighter salt intake '
              'in the week before your period are worth trying.',
          category: 'Symptom-adaptive',
          iconName: 'restaurant',
        ),
      );
    }

    if (menstrualDays >= 2 && lowWaterMenstrual >= 1) {
      tips.add(
        const AdaptiveTip(
          title: 'Hydration on heavy flow days',
          body:
              'Your logs show lighter water intake during menstruation. Extra fluids can ease fatigue '
              'and headaches — aim for steady sips through the day.',
          category: 'Phase-adaptive',
          iconName: 'water',
        ),
      );
    }

    if (highPainDays >= 3) {
      tips.add(
        AdaptiveTip(
          title: 'Pain management check-in',
          body:
              '$highPainDays high-pain days recently. If pain disrupts daily life, consider sharing '
              'your Glow PDF export with a clinician.',
          category: 'Pattern-adaptive',
          iconName: 'medical',
        ),
      );
    }

    if (lowMoodDays >= 4) {
      tips.add(
        AdaptiveTip(
          title: 'Mood support',
          body:
              'Several low-mood days logged. Sunlight, short walks, and connecting with your partner '
              'streak buddy can help — you\'re not alone in this.',
          category: 'Pattern-adaptive',
          iconName: 'favorite',
        ),
      );
    }

    final report = CorrelationEngine.analyze(health: health, cycle: cycle, lookbackDays: lookbackDays);
    for (final insight in report.insights.take(2)) {
      if (insight.kind == CorrelationInsightKind.symptomPhase) {
        tips.add(
          AdaptiveTip(
            title: 'Pattern spotted',
            body: insight.detail,
            category: 'Correlation',
            iconName: 'insights',
          ),
        );
      }
    }

    final phase = cycle.phaseForDay(cycle.currentDayInCycle, cycleLength: cycle.typicalCycleLength);
    tips.add(
      AdaptiveTip(
        title: '${phase.displayName} phase tip',
        body: _phaseTip(phase),
        category: 'Phase',
        iconName: 'cycle',
      ),
    );

    return tips.take(8).toList();
  }

  static int _countSymptom(Map<String, int> counts, List<String> keys) {
    var n = 0;
    for (final e in counts.entries) {
      if (keys.any((k) => e.key.contains(k))) n += e.value;
    }
    return n;
  }

  static String _phaseTip(CyclePhase phase) => switch (phase) {
        CyclePhase.menstrual =>
          'Rest, iron-friendly foods, and heat. It\'s okay to scale workouts down.',
        CyclePhase.follicular =>
          'Energy often rises — try new workouts or projects while motivation is up.',
        CyclePhase.ovulatory =>
          'Peak vitality for many — stay hydrated and don\'t skip meals.',
        CyclePhase.luteal =>
          'PMS may appear — stretch, reduce caffeine late day, and plan cozy evenings.',
      };
}
