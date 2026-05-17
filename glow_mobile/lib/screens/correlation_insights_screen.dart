import 'package:flutter/material.dart';

import '../models/correlation_insight.dart';
import '../services/correlation_engine.dart';
import '../services/cycle_service.dart';
import '../services/health_log_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

/// Surfaces offline correlations between cycle phase, symptoms, and daily logs.
class CorrelationInsightsScreen extends StatefulWidget {
  const CorrelationInsightsScreen({super.key});

  @override
  State<CorrelationInsightsScreen> createState() => _CorrelationInsightsScreenState();
}

class _CorrelationInsightsScreenState extends State<CorrelationInsightsScreen> {
  int _lookback = CorrelationEngine.defaultLookbackDays;

  @override
  void initState() {
    super.initState();
    HealthLogService.instance.ensureLoaded();
    CycleService.instance.ensureLoaded();
  }

  CorrelationReport _report() => CorrelationEngine.analyze(
        health: HealthLogService.instance,
        cycle: CycleService.instance,
        lookbackDays: _lookback,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const GlowPageAppBar(title: Text('Pattern insights')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          HealthLogService.instance,
          CycleService.instance,
        ]),
        builder: (context, _) {
          final report = _report();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Correlations from your logs — not diagnosis or medical advice. Patterns strengthen with more check-ins.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                useBackdropBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data window',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 30, label: Text('30d')),
                        ButtonSegment(value: 60, label: Text('60d')),
                        ButtonSegment(value: 90, label: Text('90d')),
                      ],
                      selected: {_lookback},
                      onSelectionChanged: (s) => setState(() => _lookback = s.first),
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      scheme: scheme,
                      label: 'Days with logs',
                      value: '${report.daysWithCheckIn} / ${report.daysAnalyzed}',
                    ),
                    _StatRow(
                      scheme: scheme,
                      label: 'Cycle linked',
                      value: report.cycleLinked ? 'Yes' : 'Log period to unlock',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!report.hasInsights) ...[
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    children: [
                      Icon(Icons.insights_outlined, size: 48, color: scheme.primary.withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      Text(
                        report.emptyMessage ?? 'No patterns yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                ...report.insights.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InsightCard(insight: i, scheme: scheme),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.scheme, required this.label, required this.value});

  final ColorScheme scheme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.scheme});

  final CorrelationInsight insight;
  final ColorScheme scheme;

  IconData get _icon => switch (insight.kind) {
        CorrelationInsightKind.phaseMetric => Icons.loop_rounded,
        CorrelationInsightKind.symptomPhase => Icons.healing_outlined,
        CorrelationInsightKind.metricPair => Icons.scatter_plot_outlined,
        CorrelationInsightKind.bodyZone => Icons.accessibility_new_rounded,
        CorrelationInsightKind.sleepPain => Icons.bedtime_outlined,
      };

  Color get _confidenceColor => switch (insight.confidence) {
        CorrelationConfidence.emerging => scheme.outline,
        CorrelationConfidence.moderate => scheme.tertiary,
        CorrelationConfidence.strong => scheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBackdropBlur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, color: scheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.headline,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: scheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.detail,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: _confidenceColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  insight.confidence.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _confidenceColor),
                ),
              ),
              Text(
                '${insight.sampleDays} days',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
