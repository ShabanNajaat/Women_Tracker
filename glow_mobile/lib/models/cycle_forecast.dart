import 'cycle_phase.dart';

/// One day in the forward-looking timeline.
class DayForecast {
  const DayForecast({
    required this.dateKey,
    required this.phase,
    required this.cycleDay,
    this.predictedMood,
    this.predictedEnergy,
    this.predictedPain,
    this.isFertileWindow = false,
    this.isOvulation = false,
    this.isPredictedPeriod = false,
  });

  final String dateKey;
  final CyclePhase phase;
  final int cycleDay;
  final int? predictedMood;
  final int? predictedEnergy;
  final int? predictedPain;
  final bool isFertileWindow;
  final bool isOvulation;
  final bool isPredictedPeriod;
}

/// Local statistical forecast + optional AI narrative.
class CycleForecastReport {
  const CycleForecastReport({
    required this.hasCycleAnchor,
    required this.confidenceLabel,
    required this.isIrregular,
    required this.cycleLength,
    required this.currentPhase,
    required this.currentCycleDay,
    required this.nextPeriodDate,
    required this.nextPeriodEarliest,
    required this.nextPeriodLatest,
    required this.daysUntilPeriod,
    required this.ovulationDate,
    required this.fertileWindowLabel,
    required this.timeline,
    required this.phaseMetricHints,
    this.aiNarrative,
    this.aiHighlights = const [],
    this.aiWatchFor = const [],
    this.aiNextTwoWeeksTip,
    this.aiSource,
  });

  final bool hasCycleAnchor;
  final String confidenceLabel;
  final bool isIrregular;
  final int cycleLength;
  final CyclePhase? currentPhase;
  final int currentCycleDay;
  final DateTime? nextPeriodDate;
  final DateTime? nextPeriodEarliest;
  final DateTime? nextPeriodLatest;
  final int? daysUntilPeriod;
  final DateTime? ovulationDate;
  final String? fertileWindowLabel;
  final List<DayForecast> timeline;
  final Map<CyclePhase, String> phaseMetricHints;
  final String? aiNarrative;
  final List<String> aiHighlights;
  final List<String> aiWatchFor;
  final String? aiNextTwoWeeksTip;
  final String? aiSource;

  bool get hasAiInsight => aiNarrative != null && aiNarrative!.isNotEmpty;

  String get nextPeriodLabel {
    if (nextPeriodDate == null) return 'Log your period to predict';
    if (isIrregular && nextPeriodEarliest != null && nextPeriodLatest != null) {
      return '${_fmt(nextPeriodEarliest!)} – ${_fmt(nextPeriodLatest!)}';
    }
    return _fmt(nextPeriodDate!);
  }

  static String _fmt(DateTime d) => '${d.month}/${d.day}';
}

class AiForecastPayload {
  const AiForecastPayload({
    required this.narrative,
    required this.highlights,
    required this.watchFor,
    this.nextTwoWeeksTip,
    this.source,
  });

  final String narrative;
  final List<String> highlights;
  final List<String> watchFor;
  final String? nextTwoWeeksTip;
  final String? source;

  factory AiForecastPayload.fromJson(Map<String, dynamic> m) {
    List<String> list(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    return AiForecastPayload(
      narrative: m['narrative']?.toString() ?? '',
      highlights: list(m['highlights']),
      watchFor: list(m['watchFor']),
      nextTwoWeeksTip: m['nextTwoWeeksTip'] as String?,
      source: m['source'] as String?,
    );
  }
}
