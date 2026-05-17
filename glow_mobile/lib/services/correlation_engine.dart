import 'dart:math' as math;

import '../models/body_region.dart';
import '../models/correlation_insight.dart';
import '../models/cycle_phase.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';

/// Offline pattern finder across cycle phase, symptoms, mood, pain, sleep, and body map.
abstract final class CorrelationEngine {
  static const int defaultLookbackDays = 60;
  static const int minDaysForReport = 5;
  static const int minPhaseDays = 2;

  static CorrelationReport analyze({
    required HealthLogService health,
    required CycleService cycle,
    int lookbackDays = defaultLookbackDays,
  }) {
    final end = DateTime.now();
    final series = health.rangeEnding(end, lookbackDays);
    var daysWithCheckIn = 0;
    for (final (_, log) in series) {
      if (_hasCheckIn(log)) daysWithCheckIn++;
    }

    final cycleLinked = cycle.lastPeriodStart != null;

    if (daysWithCheckIn < minDaysForReport) {
      return CorrelationReport(
        lookbackDays: lookbackDays,
        daysAnalyzed: series.length,
        daysWithCheckIn: daysWithCheckIn,
        cycleLinked: cycleLinked,
        insights: const [],
        emptyMessage:
            'Log mood, energy, pain, or symptoms on $minDaysForReport+ days to unlock pattern insights.',
      );
    }

    if (!cycleLinked) {
      final metricOnly = _metricPairInsights(series);
      return CorrelationReport(
        lookbackDays: lookbackDays,
        daysAnalyzed: series.length,
        daysWithCheckIn: daysWithCheckIn,
        cycleLinked: false,
        insights: metricOnly.take(6).toList(),
        emptyMessage: metricOnly.isEmpty
            ? 'Log your period on the calendar to unlock cycle-phase correlations.'
            : 'Log your period on the calendar for cycle-phase correlations.',
      );
    }

    final insights = <CorrelationInsight>[
      ..._phaseMetricInsights(series, cycle),
      ..._symptomPhaseInsights(series, cycle),
      ..._bodyZonePhaseInsights(series, cycle),
      ..._sleepPainInsights(series),
      ..._metricPairInsights(series),
    ];

    insights.sort((a, b) => b.strength.compareTo(a.strength));

    final deduped = <String, CorrelationInsight>{};
    for (final i in insights) {
      deduped.putIfAbsent(i.id, () => i);
    }
    final top = deduped.values.take(8).toList();

    return CorrelationReport(
      lookbackDays: lookbackDays,
      daysAnalyzed: series.length,
      daysWithCheckIn: daysWithCheckIn,
      cycleLinked: true,
      insights: top,
      emptyMessage: top.isEmpty
          ? 'Keep logging across different cycle days — patterns appear with more data.'
          : null,
    );
  }

  static bool _hasCheckIn(DailyHealthLog log) =>
      log.mood > 0 ||
      log.energy > 0 ||
      log.pain > 0 ||
      log.symptoms.isNotEmpty ||
      log.bodyPain.isNotEmpty ||
      log.sleepHours > 0;

  static CorrelationConfidence _confidence(int n) {
    if (n >= 12) return CorrelationConfidence.strong;
    if (n >= 6) return CorrelationConfidence.moderate;
    return CorrelationConfidence.emerging;
  }

  static List<CorrelationInsight> _phaseMetricInsights(
    List<(String, DailyHealthLog)> series,
    CycleService cycle,
  ) {
    final out = <CorrelationInsight>[];
    final global = _MetricBuckets();

    final byPhase = <CyclePhase, _MetricBuckets>{
      for (final p in CyclePhase.values) p: _MetricBuckets(),
    };

    for (final (key, log) in series) {
      final parts = key.split('-');
      if (parts.length != 3) continue;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final phase = cycle.phaseForDate(dt);
      if (phase == null) continue;

      global.add(log);
      byPhase[phase]!.add(log);
    }

    if (global.painN < 3 && global.moodN < 3) return out;

    for (final phase in CyclePhase.values) {
      final bucket = byPhase[phase]!;
      if (bucket.painN >= minPhaseDays && global.painN >= 5) {
        final phaseAvg = bucket.painAvg;
        final globalAvg = global.painAvg;
        final delta = phaseAvg - globalAvg;
        if (delta >= 0.75) {
          final n = bucket.painN;
          out.add(CorrelationInsight(
            id: 'phase_pain_${phase.name}',
            kind: CorrelationInsightKind.phaseMetric,
            headline: 'Higher pain in ${phase.displayName} phase',
            detail:
                'Pain averages ${phaseAvg.toStringAsFixed(1)}/5 during ${phase.displayName} days vs ${globalAvg.toStringAsFixed(1)} overall ($n logged days). Warmth, hydration, and rest may help — not medical advice.',
            strength: (delta / 4).clamp(0.0, 1.0),
            sampleDays: n,
            confidence: _confidence(n),
          ));
        } else if (delta <= -0.75) {
          final n = bucket.painN;
          out.add(CorrelationInsight(
            id: 'phase_pain_low_${phase.name}',
            kind: CorrelationInsightKind.phaseMetric,
            headline: 'Lower pain in ${phase.displayName} phase',
            detail:
                'Pain averages ${phaseAvg.toStringAsFixed(1)}/5 in ${phase.displayName} vs ${globalAvg.toStringAsFixed(1)} overall ($n days).',
            strength: (-delta / 4).clamp(0.0, 1.0),
            sampleDays: n,
            confidence: _confidence(n),
          ));
        }
      }

      if (bucket.moodN >= minPhaseDays && global.moodN >= 5) {
        final delta = bucket.moodAvg - global.moodAvg;
        if (delta <= -0.75) {
          final n = bucket.moodN;
          out.add(CorrelationInsight(
            id: 'phase_mood_${phase.name}',
            kind: CorrelationInsightKind.phaseMetric,
            headline: 'Mood tends lower in ${phase.displayName} phase',
            detail:
                'Mood averages ${bucket.moodAvg.toStringAsFixed(1)}/5 during ${phase.displayName} vs ${global.moodAvg.toStringAsFixed(1)} overall ($n days).',
            strength: (-delta / 4).clamp(0.0, 1.0),
            sampleDays: n,
            confidence: _confidence(n),
          ));
        } else if (delta >= 0.75) {
          final n = bucket.moodN;
          out.add(CorrelationInsight(
            id: 'phase_mood_high_${phase.name}',
            kind: CorrelationInsightKind.phaseMetric,
            headline: 'Mood tends higher in ${phase.displayName} phase',
            detail:
                'Mood averages ${bucket.moodAvg.toStringAsFixed(1)}/5 in ${phase.displayName} vs ${global.moodAvg.toStringAsFixed(1)} overall ($n days).',
            strength: (delta / 4).clamp(0.0, 1.0),
            sampleDays: n,
            confidence: _confidence(n),
          ));
        }
      }

      if (bucket.energyN >= minPhaseDays && global.energyN >= 5) {
        final delta = bucket.energyAvg - global.energyAvg;
        if (delta <= -0.75) {
          final n = bucket.energyN;
          out.add(CorrelationInsight(
            id: 'phase_energy_${phase.name}',
            kind: CorrelationInsightKind.phaseMetric,
            headline: 'Energy dips in ${phase.displayName} phase',
            detail:
                'Energy averages ${bucket.energyAvg.toStringAsFixed(1)}/5 during ${phase.displayName} vs ${global.energyAvg.toStringAsFixed(1)} overall ($n days).',
            strength: (-delta / 4).clamp(0.0, 1.0),
            sampleDays: n,
            confidence: _confidence(n),
          ));
        }
      }
    }
    return out;
  }

  static List<CorrelationInsight> _symptomPhaseInsights(
    List<(String, DailyHealthLog)> series,
    CycleService cycle,
  ) {
    final out = <CorrelationInsight>[];
    final symptomDays = <String, List<CyclePhase>>{};

    for (final (key, log) in series) {
      if (log.symptoms.isEmpty) continue;
      final parts = key.split('-');
      if (parts.length != 3) continue;
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final phase = cycle.phaseForDate(dt);
      if (phase == null) continue;
      for (final sx in log.symptoms) {
        symptomDays.putIfAbsent(sx, () => []).add(phase);
      }
    }

    for (final e in symptomDays.entries) {
      if (e.value.length < 2) continue;
      final counts = <CyclePhase, int>{};
      for (final p in e.value) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
      CyclePhase? topPhase;
      var topCount = 0;
      for (final c in counts.entries) {
        if (c.value > topCount) {
          topCount = c.value;
          topPhase = c.key;
        }
      }
      if (topPhase == null) continue;
      final pct = (100 * topCount / e.value.length).round();
      if (pct >= 55 && topCount >= 2) {
        out.add(CorrelationInsight(
          id: 'sx_${e.key}_${topPhase.name}',
          kind: CorrelationInsightKind.symptomPhase,
          headline: '${e.key} clusters in ${topPhase.displayName}',
          detail:
              '$topCount of ${e.value.length} days you logged “${e.key}” fell in the ${topPhase.displayName} phase ($pct%).',
          strength: (pct / 100).clamp(0.0, 1.0),
          sampleDays: e.value.length,
          confidence: _confidence(e.value.length),
        ));
      }
    }
    return out;
  }

  static List<CorrelationInsight> _bodyZonePhaseInsights(
    List<(String, DailyHealthLog)> series,
    CycleService cycle,
  ) {
    final out = <CorrelationInsight>[];
    final zonePhases = <String, List<CyclePhase>>{};

    for (final (key, log) in series) {
      if (log.bodyPain.isEmpty) continue;
      final parts = key.split('-');
      if (parts.length != 3) continue;
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final phase = cycle.phaseForDate(dt);
      if (phase == null) continue;
      for (final z in log.bodyPain.keys) {
        if ((log.bodyPain[z] ?? 0) > 0) {
          zonePhases.putIfAbsent(z, () => []).add(phase);
        }
      }
    }

    for (final e in zonePhases.entries) {
      if (e.value.length < 2) continue;
      final menstrualLuteal = e.value
          .where((p) => p == CyclePhase.menstrual || p == CyclePhase.luteal)
          .length;
      final pct = (100 * menstrualLuteal / e.value.length).round();
      if (pct >= 60) {
        final label = BodyRegions.byId(e.key)?.label ?? e.key;
        out.add(CorrelationInsight(
          id: 'zone_${e.key}_ml',
          kind: CorrelationInsightKind.bodyZone,
          headline: '$label often marks in Menstrual / Luteal',
          detail:
              '$menstrualLuteal of ${e.value.length} days with $label discomfort were menstrual or luteal phase ($pct%).',
          strength: (pct / 100).clamp(0.0, 1.0),
          sampleDays: e.value.length,
          confidence: _confidence(e.value.length),
        ));
      }
    }
    return out;
  }

  static List<CorrelationInsight> _sleepPainInsights(
    List<(String, DailyHealthLog)> series,
  ) {
    final out = <CorrelationInsight>[];
    var shortSleepHighPain = 0;
    var shortSleepDays = 0;
    var otherPainSum = 0.0;
    var otherPainN = 0;

    for (final (_, log) in series) {
      if (log.sleepHours > 0 && log.sleepHours < 6.5) {
        shortSleepDays++;
        if (log.pain >= 3) shortSleepHighPain++;
      }
      if (log.sleepHours >= 6.5 && log.pain > 0) {
        otherPainSum += log.pain;
        otherPainN++;
      }
    }

    if (shortSleepDays >= 3 && shortSleepHighPain >= 2) {
      final rate = shortSleepHighPain / shortSleepDays;
      if (rate >= 0.5) {
        final otherAvg = otherPainN > 0 ? otherPainSum / otherPainN : null;
        final detail = otherAvg != null
            ? 'On $shortSleepHighPain of $shortSleepDays short-sleep nights (<6.5h), pain was 3+/5 vs ${otherAvg.toStringAsFixed(1)} average on longer-sleep days.'
            : 'On $shortSleepHighPain of $shortSleepDays short-sleep nights (<6.5h), pain was 3+/5.';
        out.add(CorrelationInsight(
          id: 'sleep_pain_short',
          kind: CorrelationInsightKind.sleepPain,
          headline: 'Short sleep ↔ higher pain days',
          detail: detail,
          strength: rate.clamp(0.0, 1.0),
          sampleDays: shortSleepDays,
          confidence: _confidence(shortSleepDays),
        ));
      }
    }
    return out;
  }

  static List<CorrelationInsight> _metricPairInsights(
    List<(String, DailyHealthLog)> series,
  ) {
    final out = <CorrelationInsight>[];
    final moodE = <double>[], energyE = <double>[];
    final painP = <double>[], sleepS = <double>[];
    final stepsT = <double>[], energyE2 = <double>[];

    for (final (_, log) in series) {
      if (log.mood > 0 && log.energy > 0) {
        moodE.add(log.mood.toDouble());
        energyE.add(log.energy.toDouble());
      }
      if (log.pain > 0 && log.sleepHours > 0) {
        painP.add(log.pain.toDouble());
        sleepS.add(log.sleepHours);
      }
      if (log.steps > 0 && log.energy > 0) {
        stepsT.add(log.steps.toDouble());
        energyE2.add(log.energy.toDouble());
      }
    }

    _addPair(
      out,
      id: 'mood_energy',
      x: moodE,
      y: energyE,
      labelX: 'mood',
      labelY: 'energy',
      positiveGood: true,
    );
    _addPair(
      out,
      id: 'pain_sleep',
      x: painP,
      y: sleepS,
      labelX: 'pain',
      labelY: 'sleep hours',
      positiveGood: false,
      requireNegative: true,
    );
    _addPair(
      out,
      id: 'steps_energy',
      x: stepsT,
      y: energyE2,
      labelX: 'steps',
      labelY: 'energy',
      positiveGood: true,
    );
    return out;
  }

  static void _addPair(
    List<CorrelationInsight> out, {
    required String id,
    required List<double> x,
    required List<double> y,
    required String labelX,
    required String labelY,
    required bool positiveGood,
    bool requireNegative = false,
  }) {
    if (x.length < 6) return;
    final r = _pearson(x, y);
    if (r == null) return;
    if (requireNegative && r >= 0) return;
    final absR = r.abs();
    if (absR < 0.45) return;

    final direction = r > 0 ? 'rise' : 'fall';
    final good = positiveGood ? r > 0 : r < 0;
    final headline = good
        ? 'Higher $labelX ↔ higher $labelY'
        : 'When $labelX rises, $labelY tends to $direction';

    out.add(CorrelationInsight(
      id: id,
      kind: CorrelationInsightKind.metricPair,
      headline: headline,
      detail:
          'Across ${x.length} days, $labelX and $labelY move together (r=${r.toStringAsFixed(2)}). Correlation is not causation — for wellness reflection only.',
      strength: absR.clamp(0.0, 1.0),
      sampleDays: x.length,
      confidence: _confidence(x.length),
    ));
  }

  static double? _pearson(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 3) return null;
    final n = x.length;
    final mx = x.reduce((a, b) => a + b) / n;
    final my = y.reduce((a, b) => a + b) / n;
    double num = 0, dx = 0, dy = 0;
    for (var i = 0; i < n; i++) {
      final a = x[i] - mx;
      final b = y[i] - my;
      num += a * b;
      dx += a * a;
      dy += b * b;
    }
    if (dx == 0 || dy == 0) return null;
    return num / math.sqrt(dx * dy);
  }
}

class _MetricBuckets {
  double moodSum = 0, energySum = 0, painSum = 0;
  int moodN = 0, energyN = 0, painN = 0;

  void add(DailyHealthLog log) {
    if (log.mood > 0) {
      moodSum += log.mood;
      moodN++;
    }
    if (log.energy > 0) {
      energySum += log.energy;
      energyN++;
    }
    if (log.pain > 0) {
      painSum += log.pain;
      painN++;
    }
  }

  double get moodAvg => moodN > 0 ? moodSum / moodN : 0;
  double get energyAvg => energyN > 0 ? energySum / energyN : 0;
  double get painAvg => painN > 0 ? painSum / painN : 0;
}
