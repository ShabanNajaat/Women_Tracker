import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/body_region.dart';
import '../models/correlation_insight.dart';
import '../models/cycle_phase.dart';
import 'correlation_engine.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';

/// Builds a shareable PDF with health summary, charts, and pattern insights.
abstract final class HealthPdfExportService {
  static const double _chartW = 500;
  static const double _chartH = 95;

  static Future<void> shareReport({
    required HealthLogService health,
    required CycleService cycle,
    int chartDays = 14,
    int correlationLookback = 60,
  }) async {
    final bytes = await buildPdf(
      health: health,
      cycle: cycle,
      chartDays: chartDays,
      correlationLookback: correlationLookback,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'glow_health_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> buildPdf({
    required HealthLogService health,
    required CycleService cycle,
    int chartDays = 14,
    int correlationLookback = 60,
  }) async {
    await health.ensureLoaded();
    await cycle.ensureLoaded();

    final end = DateTime.now();
    final series = health.rangeEnding(end, chartDays);
    final report = CorrelationEngine.analyze(
      health: health,
      cycle: cycle,
      lookbackDays: correlationLookback,
    );
    final glow = health.weeklyGlowScore();
    final phase = cycle.phaseForDate(end);
    final dayInCycle = cycle.dayInCycleFor(end);
    final dateFmt = DateFormat.yMMMd();

    String rangeLabel() {
      if (series.isEmpty) return dateFmt.format(end);
      final first = series.first.$1.split('-');
      final last = series.last.$1.split('-');
      if (first.length == 3 && last.length == 3) {
        try {
          final a = DateTime(int.parse(first[0]), int.parse(first[1]), int.parse(first[2]));
          final b = DateTime(int.parse(last[0]), int.parse(last[1]), int.parse(last[2]));
          return '${dateFmt.format(a)} – ${dateFmt.format(b)}';
        } catch (_) {}
      }
      return 'Last $chartDays days';
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'Glow — health & wellness report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Exported ${dateFmt.format(end)} · ${rangeLabel()}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'For personal wellness only — not medical advice or diagnosis.',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
          ),
          pw.SizedBox(height: 14),
          _summaryBox(
            glow: glow,
            phase: phase,
            dayInCycle: dayInCycle,
            cycleLength: cycle.typicalCycleLength,
            daysLogged: report.daysWithCheckIn,
            chartDays: chartDays,
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Mood, energy & pain (1–5)'),
          pw.SizedBox(height: 6),
          _lineChart(
            series: series,
            seriesDefs: [
              _LineDef('Mood', (l) => l.mood, PdfColors.pink),
              _LineDef('Energy', (l) => l.energy, PdfColors.purple),
              _LineDef('Pain', (l) => l.pain, PdfColors.red),
            ],
            maxY: 5,
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Hydration (glasses / day)'),
          pw.SizedBox(height: 6),
          _barChart(
            series: series,
            value: (l) => l.waterGlasses.toDouble(),
            maxY: 12,
            color: PdfColors.blue300,
            emptyHint: 'No water logs in this window.',
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Steps'),
          pw.SizedBox(height: 6),
          _barChart(
            series: series,
            value: (l) => l.steps.toDouble(),
            maxY: _stepsMaxY(series),
            color: PdfColors.teal,
            emptyHint: 'No step data — enable wearable sync in the app.',
          ),
          if (report.hasInsights) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Pattern insights (from your logs)'),
            pw.SizedBox(height: 8),
            ...report.insights.take(5).map(_insightBlock),
          ],
          pw.SizedBox(height: 18),
          _sectionTitle('Daily log'),
          pw.SizedBox(height: 8),
          ..._dailyLogRows(series, cycle),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold));
  }

  static pw.Widget _summaryBox({
    required int? glow,
    required CyclePhase? phase,
    required int? dayInCycle,
    required int cycleLength,
    required int daysLogged,
    required int chartDays,
  }) {
    final lines = <String>[
      if (glow != null) 'Glow score (7-day): $glow / 100',
      if (phase != null && dayInCycle != null)
        'Cycle today: day $dayInCycle of ~$cycleLength · ${phase.displayName}',
      'Days with logs (last $chartDays): $daysLogged',
    ];
    if (lines.isEmpty) lines.add('Log check-ins in the app to populate this report.');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.pink50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.pink200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: lines.map((l) => pw.Text(l, style: const pw.TextStyle(fontSize: 10))).toList(),
      ),
    );
  }

  static pw.Widget _lineChart({
    required List<(String, DailyHealthLog)> series,
    required List<_LineDef> seriesDefs,
    required double maxY,
  }) {
    final hasData = seriesDefs.any((def) => series.any((e) => def.value(e.$2) > 0));
    if (!hasData) {
      return pw.Text(
        'No mood / energy / pain check-ins in this period.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: _chartW,
          height: _chartH,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.CustomPaint(
            size: PdfPoint(_chartW, _chartH),
            painter: (canvas, size) {
              for (var g = 1; g <= maxY.toInt(); g++) {
                final y = (g / maxY) * size.y;
                canvas
                  ..setStrokeColor(PdfColors.grey200)
                  ..setLineWidth(0.3)
                  ..drawLine(0, y, size.x, y)
                  ..strokePath();
              }
              for (final def in seriesDefs) {
                _paintLine(canvas, size, series, def, maxY);
              }
            },
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 12,
          children: seriesDefs
              .map(
                (d) => pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(width: 10, height: 10, color: d.color),
                    pw.SizedBox(width: 4),
                    pw.Text(d.label, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static void _paintLine(
    PdfGraphics canvas,
    PdfPoint size,
    List<(String, DailyHealthLog)> series,
    _LineDef def,
    double maxY,
  ) {
    canvas
      ..setStrokeColor(def.color)
      ..setLineWidth(1.2);

    var hasSegment = false;
    for (var i = 0; i < series.length; i++) {
      final v = def.value(series[i].$2);
      if (v <= 0) {
        if (hasSegment) canvas.strokePath();
        hasSegment = false;
        continue;
      }
      final x = (i + 0.5) / series.length * size.x;
      final y = (v / maxY) * size.y;
      if (!hasSegment) {
        canvas.moveTo(x, y);
        hasSegment = true;
      } else {
        canvas.lineTo(x, y);
      }
      canvas
        ..setFillColor(def.color)
        ..drawEllipse(x, y, 1.5, 1.5)
        ..fillPath();
    }
    if (hasSegment) canvas.strokePath();
  }

  static pw.Widget _barChart({
    required List<(String, DailyHealthLog)> series,
    required double Function(DailyHealthLog) value,
    required double maxY,
    required PdfColor color,
    required String emptyHint,
  }) {
    final hasData = series.any((e) => value(e.$2) > 0);
    if (!hasData) {
      return pw.Text(emptyHint, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600));
    }

    final effectiveMax = maxY <= 0 ? 1 : maxY;

    return pw.Container(
      width: _chartW,
      height: _chartH,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.CustomPaint(
        size: PdfPoint(_chartW, _chartH),
        painter: (canvas, size) {
          final slot = size.x / series.length;
          final barW = slot * 0.55;
          for (var i = 0; i < series.length; i++) {
            final v = value(series[i].$2);
            if (v <= 0) continue;
            final h = (v / effectiveMax) * size.y;
            final x = i * slot + (slot - barW) / 2;
            canvas
              ..setFillColor(color)
              ..drawRect(x, 0, barW, h)
              ..fillPath();
          }
        },
      ),
    );
  }

  static double _stepsMaxY(List<(String, DailyHealthLog)> series) {
    var max = 0;
    for (final e in series) {
      if (e.$2.steps > max) max = e.$2.steps;
    }
    if (max == 0) return 10000;
    final rounded = ((max / 2000).ceil() * 2000);
    return rounded < 4000 ? 4000.0 : rounded.toDouble();
  }

  static pw.Widget _insightBlock(CorrelationInsight insight) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '• ${insight.headline}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            insight.detail,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _dailyLogRows(
    List<(String, DailyHealthLog)> series,
    CycleService cycle,
  ) {
    final rows = <pw.Widget>[];
    final dateFmt = DateFormat.MMMd();

    for (final (key, log) in series.reversed) {
      if (!_rowHasData(log)) continue;
      final parts = key.split('-');
      String dateLabel = key;
      CyclePhase? phase;
      if (parts.length == 3) {
        try {
          final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          dateLabel = dateFmt.format(d);
          phase = cycle.phaseForDate(d);
        } catch (_) {}
      }

      final bits = <String>[];
      if (log.mood > 0) bits.add('Mood ${log.mood}');
      if (log.energy > 0) bits.add('Energy ${log.energy}');
      if (log.pain > 0) bits.add('Pain ${log.pain}');
      if (log.sleepHours > 0) bits.add('Sleep ${log.sleepHours.toStringAsFixed(1)}h');
      if (log.waterGlasses > 0) bits.add('Water ${log.waterGlasses}');
      if (log.steps > 0) bits.add('Steps ${log.steps}');
      if (log.symptoms.isNotEmpty) bits.add('Sx: ${log.symptoms.join(', ')}');
      if (log.bodyPain.isNotEmpty) {
        final zones = log.bodyPain.entries
            .where((e) => e.value > 0)
            .map((e) => BodyRegions.byId(e.key)?.label ?? e.key)
            .take(3)
            .join(', ');
        if (zones.isNotEmpty) bits.add('Body: $zones');
      }
      if (phase != null) bits.add(phase.displayName);

      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$dateLabel — ',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: bits.join(' · '), style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      rows.add(
        pw.Text(
          'No daily entries in this window.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      );
    }
    return rows;
  }

  static bool _rowHasData(DailyHealthLog log) =>
      log.mood > 0 ||
      log.energy > 0 ||
      log.pain > 0 ||
      log.sleepHours > 0 ||
      log.waterGlasses > 0 ||
      log.steps > 0 ||
      log.symptoms.isNotEmpty ||
      log.bodyPain.isNotEmpty;
}

class _LineDef {
  const _LineDef(this.label, this.value, this.color);
  final String label;
  final int Function(DailyHealthLog) value;
  final PdfColor color;
}
