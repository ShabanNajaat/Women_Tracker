/// A single pattern surfaced by the local correlation engine (not causal medical advice).
enum CorrelationInsightKind {
  phaseMetric,
  symptomPhase,
  metricPair,
  bodyZone,
  sleepPain,
}

enum CorrelationConfidence {
  emerging,
  moderate,
  strong;

  String get label => switch (this) {
        emerging => 'Emerging',
        moderate => 'Moderate',
        strong => 'Strong',
      };
}

class CorrelationInsight {
  const CorrelationInsight({
    required this.id,
    required this.kind,
    required this.headline,
    required this.detail,
    required this.strength,
    required this.sampleDays,
    required this.confidence,
  });

  final String id;
  final CorrelationInsightKind kind;
  final String headline;
  final String detail;
  /// 0–1, used for sorting only.
  final double strength;
  final int sampleDays;
  final CorrelationConfidence confidence;
}

class CorrelationReport {
  const CorrelationReport({
    required this.lookbackDays,
    required this.daysAnalyzed,
    required this.daysWithCheckIn,
    required this.cycleLinked,
    required this.insights,
    this.emptyMessage,
  });

  final int lookbackDays;
  final int daysAnalyzed;
  final int daysWithCheckIn;
  final bool cycleLinked;
  final List<CorrelationInsight> insights;
  final String? emptyMessage;

  bool get hasInsights => insights.isNotEmpty;

  String get summaryLine {
    if (!hasInsights) return emptyMessage ?? 'Keep logging to discover patterns.';
    final top = insights.first.headline;
    if (insights.length == 1) return top;
    return '$top · +${insights.length - 1} more';
  }
}
