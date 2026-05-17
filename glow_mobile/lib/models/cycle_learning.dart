/// Stats derived from logged period starts (local, not medical-grade).
class CycleLearningSnapshot {
  const CycleLearningSnapshot({
    required this.periodStartsLogged,
    required this.validIntervals,
    required this.averageCycleLength,
    required this.shortestCycle,
    required this.longestCycle,
    required this.isIrregular,
    required this.confidence,
  });

  final int periodStartsLogged;
  final List<int> validIntervals;
  final int? averageCycleLength;
  final int? shortestCycle;
  final int? longestCycle;
  final bool isIrregular;
  final CyclePredictionConfidence confidence;

  bool get isPersonalized => validIntervals.length >= CycleLearningRules.minIntervalsToPersonalize;

  String get confidenceLabel {
    switch (confidence) {
      case CyclePredictionConfidence.none:
        return 'Default estimate';
      case CyclePredictionConfidence.low:
        return 'Early estimate';
      case CyclePredictionConfidence.medium:
        return 'Learning your rhythm';
      case CyclePredictionConfidence.high:
        return 'Personalized';
    }
  }
}

enum CyclePredictionConfidence { none, low, medium, high }

/// Rules for on-device cycle length learning.
abstract final class CycleLearningRules {
  static const int minIntervalsToPersonalize = 2;
  static const int minCycleDays = 18;
  static const int maxCycleDays = 45;
  static const int irregularSpreadDays = 8;
  static const int maxHistoryEntries = 36;

  static CycleLearningSnapshot compute(List<DateTime> sortedStarts) {
    final intervals = <int>[];
    for (var i = 1; i < sortedStarts.length; i++) {
      final days = sortedStarts[i].difference(sortedStarts[i - 1]).inDays;
      if (days >= minCycleDays && days <= maxCycleDays) {
        intervals.add(days);
      }
    }

    if (intervals.isEmpty) {
      return CycleLearningSnapshot(
        periodStartsLogged: sortedStarts.length,
        validIntervals: const [],
        averageCycleLength: null,
        shortestCycle: null,
        longestCycle: null,
        isIrregular: false,
        confidence: sortedStarts.isEmpty
            ? CyclePredictionConfidence.none
            : CyclePredictionConfidence.low,
      );
    }

    final sum = intervals.reduce((a, b) => a + b);
    final avg = (sum / intervals.length).round();
    final shortest = intervals.reduce((a, b) => a < b ? a : b);
    final longest = intervals.reduce((a, b) => a > b ? a : b);
    final spread = longest - shortest;
    final irregular = intervals.length >= 2 && spread >= irregularSpreadDays;

    final confidence = switch (intervals.length) {
      >= 3 => CyclePredictionConfidence.high,
      2 => CyclePredictionConfidence.medium,
      1 => CyclePredictionConfidence.low,
      _ => CyclePredictionConfidence.none,
    };

    return CycleLearningSnapshot(
      periodStartsLogged: sortedStarts.length,
      validIntervals: List.unmodifiable(intervals),
      averageCycleLength: avg,
      shortestCycle: shortest,
      longestCycle: longest,
      isIrregular: irregular,
      confidence: confidence,
    );
  }
}
