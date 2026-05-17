import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cycle_forecast.dart';
import 'api_service.dart';
import 'cycle_forecast_engine.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';

/// Builds local forecasts and optionally enriches with server AI narrative.
class AiForecastService {
  AiForecastService._();
  static final AiForecastService instance = AiForecastService._();

  static const _cacheKey = 'glow_ai_forecast_cache_v1';
  static const _cacheTtlMs = 12 * 60 * 60 * 1000;

  final ApiService _api = ApiService();

  Future<CycleForecastReport> loadForecast({bool refreshAi = false}) async {
    await CycleService.instance.ensureLoaded();
    await HealthLogService.instance.ensureLoaded();

    final cycle = CycleService.instance;
    final health = HealthLogService.instance;
    var report = CycleForecastEngine.build(cycle: cycle, health: health);

    if (!report.hasCycleAnchor) return report;

    if (!refreshAi) {
      final cached = await _readCache();
      if (cached != null) {
        report = _mergeAi(report, cached);
        return report;
      }
    }

    if (!_api.isAuthenticated) return report;

    try {
      final ctx = CycleForecastEngine.contextForAi(report, health);
      final res = await _api.post('/forecast/ai', body: {'context': ctx});
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body);
        if (m is Map<String, dynamic>) {
          final ai = AiForecastPayload.fromJson(m);
          await _writeCache(ai);
          report = _mergeAi(report, ai);
        }
      }
    } catch (_) {}

    return report;
  }

  CycleForecastReport _mergeAi(CycleForecastReport base, AiForecastPayload ai) {
    return CycleForecastReport(
      hasCycleAnchor: base.hasCycleAnchor,
      confidenceLabel: base.confidenceLabel,
      isIrregular: base.isIrregular,
      cycleLength: base.cycleLength,
      currentPhase: base.currentPhase,
      currentCycleDay: base.currentCycleDay,
      nextPeriodDate: base.nextPeriodDate,
      nextPeriodEarliest: base.nextPeriodEarliest,
      nextPeriodLatest: base.nextPeriodLatest,
      daysUntilPeriod: base.daysUntilPeriod,
      ovulationDate: base.ovulationDate,
      fertileWindowLabel: base.fertileWindowLabel,
      timeline: base.timeline,
      phaseMetricHints: base.phaseMetricHints,
      aiNarrative: ai.narrative.isNotEmpty ? ai.narrative : null,
      aiHighlights: ai.highlights,
      aiWatchFor: ai.watchFor,
      aiNextTwoWeeksTip: ai.nextTwoWeeksTip,
      aiSource: ai.source,
    );
  }

  Future<AiForecastPayload?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final at = (m['cachedAtMs'] as num?)?.toInt() ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - at > _cacheTtlMs) return null;
      return AiForecastPayload.fromJson(Map<String, dynamic>.from(m['payload'] as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(AiForecastPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'cachedAtMs': DateTime.now().millisecondsSinceEpoch,
        'payload': {
          'narrative': payload.narrative,
          'highlights': payload.highlights,
          'watchFor': payload.watchFor,
          'nextTwoWeeksTip': payload.nextTwoWeeksTip,
          'source': payload.source,
        },
      }),
    );
  }
}
