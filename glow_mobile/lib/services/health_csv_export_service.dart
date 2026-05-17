import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'correlation_engine.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';

/// CSV export for doctors, fertility consults, or personal spreadsheets.
abstract final class HealthCsvExportService {
  static Future<void> copyToClipboard({
    required HealthLogService health,
    required CycleService cycle,
    int days = 90,
  }) async {
    final csv = buildCsv(health: health, cycle: cycle, days: days);
    await Clipboard.setData(ClipboardData(text: csv));
  }

  static String buildCsv({
    required HealthLogService health,
    required CycleService cycle,
    int days = 90,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'date,cycle_day,phase,mood,energy,pain,sleep_hours,water_glasses,steps,symptoms,body_pain_regions',
    );

    final series = health.rangeEnding(DateTime.now(), days);
    for (final (dateKey, log) in series) {
      final parts = dateKey.split('-');
      var phase = '';
      var cycleDay = '';
      if (parts.length == 3 && cycle.lastPeriodStart != null) {
        try {
          final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          final day = cycle.dayInCycleFor(d);
          if (day != null) {
            cycleDay = '$day';
            phase = cycle.phaseForDay(day, cycleLength: cycle.typicalCycleLength).name;
          }
        } catch (_) {}
      }
      final symptoms = log.symptoms.join('; ');
      final painRegions = log.bodyPain.entries.map((e) => '${e.key}:${e.value}').join('; ');
      buf.writeln(
        [
          dateKey,
          cycleDay,
          phase,
          log.mood,
          log.energy,
          log.pain,
          log.sleepHours.toStringAsFixed(1),
          log.waterGlasses,
          log.steps,
          _escape(symptoms),
          _escape(painRegions),
        ].join(','),
      );
    }

    buf.writeln();
    buf.writeln('# Glow correlation summary (${DateFormat.yMMMd().format(DateTime.now())})');
    final report = CorrelationEngine.analyze(health: health, cycle: cycle, lookbackDays: days);
    for (final i in report.insights.take(10)) {
      buf.writeln('# ${_escape('${i.headline}: ${i.detail}')}');
    }

    return buf.toString();
  }

  static String _escape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
