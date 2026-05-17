import '../models/cycle_forecast.dart';
import '../models/cycle_phase.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';

/// On-device cycle + wellness forecasting from logs (no network).
abstract final class CycleForecastEngine {
  static const int timelineDays = 21;

  static CycleForecastReport build({
    required CycleService cycle,
    required HealthLogService health,
    int healthLookback = 60,
  }) {
    if (!cycle.hasCycleAnchor) {
      return CycleForecastReport(
        hasCycleAnchor: false,
        confidenceLabel: 'No period logged',
        isIrregular: false,
        cycleLength: cycle.typicalCycleLength,
        currentPhase: null,
        currentCycleDay: 1,
        nextPeriodDate: null,
        nextPeriodEarliest: null,
        nextPeriodLatest: null,
        daysUntilPeriod: null,
        ovulationDate: null,
        fertileWindowLabel: null,
        timeline: const [],
        phaseMetricHints: const {},
      );
    }

    final learning = cycle.learning;
    final len = cycle.typicalCycleLength;
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final next = cycle.predictedNextPeriodStart;
    final spread = learning.isIrregular && learning.shortestCycle != null && learning.longestCycle != null
        ? ((learning.longestCycle! - learning.shortestCycle!) / 2).round().clamp(1, 5)
        : 0;

    DateTime? earliest;
    DateTime? latest;
    if (next != null) {
      if (spread > 0) {
        earliest = next.subtract(Duration(days: spread));
        latest = next.add(Duration(days: spread));
      }
    }

    final phaseAvgs = _phaseAverages(health, cycle, healthLookback);
    final phaseHints = <CyclePhase, String>{};
    for (final phase in CyclePhase.values) {
      final m = phaseAvgs[phase];
      if (m == null) continue;
      final parts = <String>[];
      if (m.moodN >= 2) parts.add('mood ~${m.moodAvg.toStringAsFixed(1)}/5');
      if (m.energyN >= 2) parts.add('energy ~${m.energyAvg.toStringAsFixed(1)}/5');
      if (m.painN >= 2) parts.add('pain ~${m.painAvg.toStringAsFixed(1)}/5');
      if (parts.isNotEmpty) {
        phaseHints[phase] = 'When you log during ${phase.displayName}: ${parts.join(', ')}';
      }
    }

    final timeline = <DayForecast>[];
    final anchor = DateTime(
      cycle.lastPeriodStart!.year,
      cycle.lastPeriodStart!.month,
      cycle.lastPeriodStart!.day,
    );

    for (var i = 0; i < timelineDays; i++) {
      final dt = t0.add(Duration(days: i));
      final key = HealthLogService.dateKey(dt);
      final cycleDay = _simulatedCycleDay(dt, anchor, len);
      final phase = cycle.phaseForDay(cycleDay, cycleLength: len);
      final avgs = phaseAvgs[phase];

      final ov = cycle.estimatedOvulationDate;
      final isOv = ov != null && _sameDay(dt, ov);
      final isFertile = cycle.isDateInApproximateFertileWindow(dt);
      final isPredPeriod = next != null && _sameDay(dt, next);

      timeline.add(
        DayForecast(
          dateKey: key,
          phase: phase,
          cycleDay: cycleDay,
          predictedMood: avgs != null && avgs.moodN >= 2 ? avgs.moodAvg.round().clamp(1, 5) : null,
          predictedEnergy: avgs != null && avgs.energyN >= 2 ? avgs.energyAvg.round().clamp(1, 5) : null,
          predictedPain: avgs != null && avgs.painN >= 2 ? avgs.painAvg.round().clamp(1, 5) : null,
          isFertileWindow: isFertile,
          isOvulation: isOv,
          isPredictedPeriod: isPredPeriod,
        ),
      );
    }

    return CycleForecastReport(
      hasCycleAnchor: true,
      confidenceLabel: learning.confidenceLabel,
      isIrregular: learning.isIrregular,
      cycleLength: len,
      currentPhase: cycle.phaseForDay(cycle.currentDayInCycle, cycleLength: len),
      currentCycleDay: cycle.currentDayInCycle,
      nextPeriodDate: next,
      nextPeriodEarliest: earliest,
      nextPeriodLatest: latest,
      daysUntilPeriod: cycle.daysUntilNextPeriod,
      ovulationDate: cycle.estimatedOvulationDate,
      fertileWindowLabel: cycle.fertilityWindowRangeLabel,
      timeline: timeline,
      phaseMetricHints: phaseHints,
    );
  }

  static int _simulatedCycleDay(DateTime date, DateTime anchorStart, int cycleLength) {
    var start = anchorStart;
    final d0 = DateTime(date.year, date.month, date.day);
    while (d0.difference(start).inDays >= cycleLength) {
      start = start.add(Duration(days: cycleLength));
    }
    return d0.difference(start).inDays + 1;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Map<CyclePhase, _PhaseAvg> _phaseAverages(
    HealthLogService health,
    CycleService cycle,
    int lookback,
  ) {
    final out = <CyclePhase, _PhaseAvg>{
      for (final p in CyclePhase.values) p: _PhaseAvg(),
    };
    for (final (key, log) in health.rangeEnding(DateTime.now(), lookback)) {
      final parts = key.split('-');
      if (parts.length != 3) continue;
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final phase = cycle.phaseForDate(dt);
      if (phase == null) continue;
      final bucket = out[phase]!;
      if (log.mood > 0) {
        bucket.moodSum += log.mood;
        bucket.moodN++;
      }
      if (log.energy > 0) {
        bucket.energySum += log.energy;
        bucket.energyN++;
      }
      if (log.pain > 0) {
        bucket.painSum += log.pain;
        bucket.painN++;
      }
    }
    return out;
  }

  static Map<String, dynamic> contextForAi(CycleForecastReport report, HealthLogService health) {
    String? topSymptom;
    final sxCounts = <String, int>{};
    for (final (_, log) in health.rangeEnding(DateTime.now(), 60)) {
      for (final s in log.symptoms) {
        sxCounts[s] = (sxCounts[s] ?? 0) + 1;
      }
    }
    if (sxCounts.isNotEmpty) {
      topSymptom = sxCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    return {
      'cycleLength': report.cycleLength,
      'currentPhase': report.currentPhase?.name,
      'currentCycleDay': report.currentCycleDay,
      'daysUntilPeriod': report.daysUntilPeriod,
      'nextPeriodDate': report.nextPeriodDate?.toIso8601String().split('T').first,
      'nextPeriodWindow': report.isIrregular
          ? '${report.nextPeriodEarliest?.toIso8601String().split('T').first} to ${report.nextPeriodLatest?.toIso8601String().split('T').first}'
          : null,
      'ovulationDate': report.ovulationDate?.toIso8601String().split('T').first,
      'fertileWindow': report.fertileWindowLabel,
      'isIrregular': report.isIrregular,
      'confidenceLabel': report.confidenceLabel,
      'phaseHints': report.phaseMetricHints.map((k, v) => MapEntry(k.name, v)),
      'glowScore7d': health.weeklyGlowScore(),
      'topSymptom': topSymptom,
    };
  }
}

class _PhaseAvg {
  double moodSum = 0, energySum = 0, painSum = 0;
  int moodN = 0, energyN = 0, painN = 0;

  double get moodAvg => moodN > 0 ? moodSum / moodN : 0;
  double get energyAvg => energyN > 0 ? energySum / energyN : 0;
  double get painAvg => painN > 0 ? painSum / painN : 0;
}
