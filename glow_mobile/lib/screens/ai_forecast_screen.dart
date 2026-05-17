import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cycle_forecast.dart';
import '../models/cycle_phase.dart';
import '../services/ai_forecast_service.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

class AiForecastScreen extends StatefulWidget {
  const AiForecastScreen({super.key});

  @override
  State<AiForecastScreen> createState() => _AiForecastScreenState();
}

class _AiForecastScreenState extends State<AiForecastScreen> {
  CycleForecastReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(refreshAi: false);
  }

  Future<void> _load({required bool refreshAi}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await AiForecastService.instance.loadForecast(refreshAi: refreshAi);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not build forecast.';
        _loading = false;
      });
    }
  }

  Color _phaseColor(CyclePhase phase, ColorScheme scheme) {
    return switch (phase) {
      CyclePhase.menstrual => scheme.error.withValues(alpha: 0.75),
      CyclePhase.follicular => scheme.tertiary.withValues(alpha: 0.85),
      CyclePhase.ovulatory => scheme.primary,
      CyclePhase.luteal => scheme.secondary.withValues(alpha: 0.9),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final report = _report;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: GlowPageAppBar(
        title: const Text('AI forecast'),
        actions: [
          IconButton(
            tooltip: 'Refresh AI insight',
            onPressed: _loading ? null : () => _load(refreshAi: true),
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: scheme.primary))
          : RefreshIndicator(
              onRefresh: () => _load(refreshAi: true),
              color: scheme.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    'Combines your cycle history, check-ins, and optional AI narrative. Educational only — not medical advice.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.45),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  if (report != null && !report.hasCycleAnchor) ...[
                    const SizedBox(height: 24),
                    GlassCard(
                      useBackdropBlur: false,
                      child: Text(
                        'Log your period on the calendar to unlock personalized forecasts.',
                        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                  ],
                  if (report != null && report.hasCycleAnchor) ...[
                    const SizedBox(height: 16),
                    _SummaryGrid(report: report, scheme: scheme),
                    const SizedBox(height: 16),
                    if (report.hasAiInsight) ...[
                      GlassCard(
                        useBackdropBlur: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'AI insight',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                if (report.aiSource != null)
                                  Text(
                                    report.aiSource!,
                                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              report.aiNarrative!,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.5,
                                fontSize: 14,
                              ),
                            ),
                            if (report.aiHighlights.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...report.aiHighlights.map(
                                (h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(color: scheme.primary)),
                                      Expanded(
                                        child: Text(
                                          h,
                                          style: TextStyle(
                                            color: scheme.onSurface,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (report.aiNextTwoWeeksTip != null &&
                                report.aiNextTwoWeeksTip!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                report.aiNextTwoWeeksTip!,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else if (!ApiService().isAuthenticated) ...[
                      GlassCard(
                        useBackdropBlur: false,
                        child: Text(
                          'Sign in and tap refresh to generate an AI narrative (needs server OPENAI_API_KEY or GEMINI_API_KEY). Statistical forecast below still works offline.',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Next ${report.timeline.length} days — phase timeline',
                      style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      useBackdropBlur: false,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      child: SizedBox(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final day in report.timeline) ...[
                              Expanded(
                                child: Tooltip(
                                  message:
                                      '${day.dateKey}\n${day.phase.displayName}${day.predictedMood != null ? '\nMood ~${day.predictedMood}' : ''}',
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        height: 56,
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: _phaseColor(day.phase, scheme),
                                          borderRadius: BorderRadius.circular(4),
                                          border: day.isPredictedPeriod
                                              ? Border.all(color: scheme.error, width: 2)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        day.dateKey.split('-').last,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: CyclePhase.values.map((p) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _phaseColor(p, scheme),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(p.displayName, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                          ],
                        );
                      }).toList(),
                    ),
                    if (report.phaseMetricHints.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Your logged patterns by phase',
                        style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      ...report.phaseMetricHints.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            useBackdropBlur: false,
                            child: Text(
                              e.value,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report, required this.scheme});

  final CycleForecastReport report;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.MMMd();
    String fmt(DateTime? d) => d != null ? dateFmt.format(d) : '—';

    return GlassCard(
      useBackdropBlur: false,
      child: Column(
        children: [
          _row('Confidence', report.confidenceLabel),
          _row('Current phase', report.currentPhase?.displayName ?? '—'),
          _row('Cycle day', '${report.currentCycleDay} of ~${report.cycleLength}'),
          _row('Next period', report.nextPeriodLabel),
          if (report.daysUntilPeriod != null)
            _row('Days until period', '${report.daysUntilPeriod}'),
          if (report.ovulationDate != null) _row('Est. ovulation', fmt(report.ovulationDate)),
          if (report.fertileWindowLabel != null) _row('Fertile window', report.fertileWindowLabel!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
