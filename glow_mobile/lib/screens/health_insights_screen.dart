import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cycle_phase.dart';
import '../models/fertility_intent.dart';
import '../services/cycle_service.dart';
import '../services/health_log_service.dart';
import '../services/wearable_health_service.dart';
import '../models/body_region.dart';
import '../screens/body_pain_map_screen.dart';
import '../screens/ai_forecast_screen.dart';
import '../screens/correlation_insights_screen.dart';
import '../services/correlation_engine.dart';
import '../services/adaptive_tips_service.dart';
import '../services/buddy_challenge_service.dart';
import '../services/challenge_service.dart';
import '../services/health_csv_export_service.dart';
import '../services/health_pdf_export_service.dart';
import '../widgets/symptom_trend_chart.dart';
import '../screens/medication_reminders_screen.dart';
import '../services/medication_reminder_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

/// Visual lifestyle dashboard: trends, quick check-ins, phase-aware tips.
class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  static const _symptomChips = [
    'Cramps',
    'Bloating',
    'Acne',
    'Headache',
    'Back pain',
    'Breast tenderness',
    'Nausea',
    'Cravings',
    'Fatigue',
    'Poor sleep',
    'Anxiety',
    'Low mood',
    'Irritability',
    'Spotting',
    'Heavy flow',
    'Light flow',
    'Hot flashes',
    'Dizziness',
    'Brain fog',
    'Constipation',
    'Sensitivity',
  ];

  int _mood = 3;
  int _energy = 3;
  int _pain = 1;
  double _sleep = 7;
  int _water = 4;
  bool _exportingPdf = false;
  bool _exportingCsv = false;
  final _customSx = TextEditingController();

  @override
  void initState() {
    super.initState();
    HealthLogService.instance.ensureLoaded().then((_) {
      if (mounted) setState(_loadDraft);
    });
    CycleService.instance.ensureLoaded();
    MedicationReminderService.instance.ensureLoaded();
  }

  void _loadDraft() {
    final t = HealthLogService.instance.logForDate(DateTime.now());
    _mood = t.mood > 0 ? t.mood : 3;
    _energy = t.energy > 0 ? t.energy : 3;
    _pain = t.pain > 0 ? t.pain : 1;
    _sleep = t.sleepHours > 0 ? t.sleepHours : 7;
    if (t.sleepFromWearable && t.sleepHours > 0) {
      _sleep = t.sleepHours;
    }
    _water = t.waterGlasses > 0 ? t.waterGlasses : 4;
  }

  @override
  void dispose() {
    _customSx.dispose();
    super.dispose();
  }

  String _bodyPainSubtitle(DailyHealthLog todayLog) {
    final zones = todayLog.bodyPain.entries.where((e) => e.value > 0).toList();
    if (zones.isEmpty) {
      return 'Tap zones on a front/back figure — mild to severe';
    }
    zones.sort((a, b) => b.value.compareTo(a.value));
    final top = BodyRegions.byId(zones.first.key)?.label ?? zones.first.key;
    if (zones.length == 1) {
      return '$top · ${BodyPainLevel.label(zones.first.value)}';
    }
    return '${zones.length} zones · strongest: $top';
  }

  Future<void> _exportCsv() async {
    setState(() => _exportingCsv = true);
    try {
      await HealthCsvExportService.copyToClipboard(
        health: HealthLogService.instance,
        cycle: CycleService.instance,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV copied — paste into Excel, Google Sheets, or email to your doctor.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not build CSV export.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  Map<String, int> _symptomCounts(List<(String, DailyHealthLog)> series) {
    final counts = <String, int>{};
    for (final (_, log) in series) {
      for (final s in log.symptoms) {
        final k = s.trim();
        if (k.isEmpty) continue;
        counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<void> _exportHealthPdf() async {
    setState(() => _exportingPdf = true);
    try {
      await HealthPdfExportService.shareReport(
        health: HealthLogService.instance,
        cycle: CycleService.instance,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not build health PDF. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _saveCheckIn() async {
    final t = HealthLogService.instance.logForDate(DateTime.now());
    await HealthLogService.instance.saveToday(
      mood: _mood,
      energy: _energy,
      pain: _pain,
      sleepHours: _sleep,
      waterGlasses: _water,
      symptoms: t.symptoms,
    );
    await ChallengeService.instance.recordTodayProgressIfNeeded();
    await BuddyChallengeService.instance.syncFromHealthLog();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today’s check-in saved — graphs updated.')),
      );
    }
  }

  String _insight(CycleService cycle, HealthLogService health) {
    final phase = cycle.phaseForDay(
      cycle.currentDayInCycle,
      cycleLength: cycle.typicalCycleLength,
    );
    final score = health.weeklyGlowScore();
    final buf = StringBuffer()
      ..write(
        switch (phase) {
          CyclePhase.menstrual =>
            'Menstrual phase: iron-rich snacks, warmth, and gentler workouts usually feel best. ',
          CyclePhase.follicular =>
            'Follicular phase: rising estrogen often lifts focus — good window for strength or new habits. ',
          CyclePhase.ovulatory =>
            'Ovulatory phase: peak energy for many — balance intensity with hydration. ',
          CyclePhase.luteal =>
            'Luteal phase: progesterone can bring fatigue or cravings — magnesium-rich foods and slower cardio often help. ',
        },
      );
    if (score != null) {
      if (score >= 70) {
        buf.write(
          'Your logged mood & energy this week look strong — keep the small habits that got you here.',
        );
      } else if (score >= 40) {
        buf.write(
          'Steady progress — even one daily check-in makes patterns easier to see over time.',
        );
      } else {
        buf.write(
          'If pain or low mood show up often in your logs, consider sharing trends with a clinician when you can.',
        );
      }
    } else {
      buf.write('Log mood & energy a few days in a row to unlock your Glow trend score.');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: GlowPageAppBar(
        title: const Text('Health insights'),
        actions: [
          IconButton(
            tooltip: 'Export health PDF',
            onPressed: _exportingPdf ? null : _exportHealthPdf,
            icon: _exportingPdf
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          HealthLogService.instance,
          CycleService.instance,
          WearableHealthService.instance,
        ]),
        builder: (context, _) {
          final cycle = CycleService.instance;
          final health = HealthLogService.instance;
          final todayLog = health.logForDate(DateTime.now());
          final phase = cycle.phaseForDay(
            cycle.currentDayInCycle,
            cycleLength: cycle.typicalCycleLength,
          );
          final glow = health.weeklyGlowScore();
          final series = health.rangeEnding(DateTime.now(), 14);
          final series30 = health.rangeEnding(DateTime.now(), 30);
          final symptomCounts = _symptomCounts(series30);
          final adaptiveTips = AdaptiveTipsService.generate(cycle: cycle, health: health);
          final wearable = WearableHealthService.instance;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'See how rest, mood, and your cycle line up. For wellness only — not a diagnosis.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (wearable.isPlatformSupported) ...[
                _WearableSyncBanner(scheme: scheme, wearable: wearable),
                const SizedBox(height: 12),
              ],
              if (todayLog.steps > 0 || todayLog.restingHeartRateBpm > 0) ...[
                GlassCard(
                  useBackdropBlur: false,
                  child: Row(
                    children: [
                      if (todayLog.steps > 0)
                        Expanded(
                          child: _MiniStat(
                            scheme: scheme,
                            label: 'Steps today',
                            value: '${todayLog.steps}',
                            icon: Icons.directions_walk_rounded,
                          ),
                        ),
                      if (todayLog.restingHeartRateBpm > 0)
                        Expanded(
                          child: _MiniStat(
                            scheme: scheme,
                            label: 'Heart rate',
                            value: '${todayLog.restingHeartRateBpm} bpm',
                            icon: Icons.favorite_outline_rounded,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              GlassCard(
                useBackdropBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today’s phase',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phase.displayName,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phase.description,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (cycle.personalizedPredictionCaption != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        cycle.personalizedPredictionCaption!,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (cycle.approximateFertileWindow != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        cycle.fertilityIntent == FertilityIntent.avoidPregnancy
                            ? 'Higher-fertility window (estimate): '
                            : 'Approx. fertile window (estimate): '
                        '${DateFormat.MMMd().format(cycle.approximateFertileWindow!.$1)} – '
                        '${DateFormat.MMMd().format(cycle.approximateFertileWindow!.$2)}',
                        style: TextStyle(
                          color: cycle.fertilityIntent == FertilityIntent.avoidPregnancy
                              ? scheme.error
                              : scheme.tertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (cycle.modeSpecificPhaseTip(phase) != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        cycle.modeSpecificPhaseTip(phase)!,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                useBackdropBlur: false,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: glow != null ? glow / 100 : 0,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: scheme.surfaceContainerHighest,
                              color: scheme.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                glow != null ? '$glow' : '—',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface,
                                ),
                              ),
                              Text(
                                'Glow (7d)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mood · energy · comfort · sleep · hydration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                useBackdropBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lifestyle insight',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _insight(cycle, health),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                useBackdropBlur: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                  title: Text(
                    'AI forecast',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    cycle.hasCycleAnchor
                        ? 'Period timing, phase timeline & optional AI narrative'
                        : 'Log your period to unlock forecasts',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AiForecastScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                useBackdropBlur: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.hub_outlined, color: scheme.primary),
                  title: Text(
                    'Pattern insights',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    CorrelationEngine.analyze(health: health, cycle: cycle).summaryLine,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CorrelationInsightsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                useBackdropBlur: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.medication_liquid_outlined, color: scheme.primary),
                  title: Text(
                    'Medication reminders',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    MedicationReminderService.instance.reminders.isEmpty
                        ? 'Birth control, pain relief, supplements — daily local alerts'
                        : '${MedicationReminderService.instance.reminders.where((r) => r.enabled).length} active on this device',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MedicationRemindersScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                useBackdropBlur: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.accessibility_new_rounded, color: scheme.primary),
                  title: Text(
                    'Body pain map',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _bodyPainSubtitle(todayLog),
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BodyPainMapScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '1-tap check-in',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                useBackdropBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sliderRow(scheme, 'Mood', _mood, (v) => setState(() => _mood = v)),
                    _sliderRow(scheme, 'Energy', _energy, (v) => setState(() => _energy = v)),
                    _sliderRow(scheme, 'Pain / discomfort', _pain, (v) => setState(() => _pain = v)),
                    Text(
                      todayLog.sleepFromWearable && todayLog.sleepHours > 0
                          ? 'Sleep (hours) — from ${wearable.platformLabel}'
                          : 'Sleep (hours)',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Slider(
                      value: _sleep,
                      min: 0,
                      max: 12,
                      divisions: 24,
                      label: _sleep.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _sleep = v),
                    ),
                    Row(
                      children: [
                        Text(
                          'Water (glasses)',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _water = (_water - 1).clamp(0, 20)),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_water',
                          style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _water = (_water + 1).clamp(0, 20)),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveCheckIn,
                        child: const Text('Save today’s check-in'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Symptoms (tap to toggle)',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                useBackdropBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symptomChips.map((s) {
                        final on = todayLog.symptoms.contains(s);
                        return FilterChip(
                          label: Text(s),
                          selected: on,
                          onSelected: (_) async {
                            await health.toggleSymptomToday(s);
                            if (mounted) setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customSx,
                            decoration: const InputDecoration(
                              hintText: 'Custom symptom',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addCustom(health),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                          ),
                          onPressed: () => _addCustom(health),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Symptom patterns (30 days)',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                useBackdropBlur: false,
                padding: const EdgeInsets.all(16),
                child: SymptomTrendChart(symptomCounts: symptomCounts),
              ),
              if (adaptiveTips.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Adaptive tips for you',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final tip in adaptiveTips.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      useBackdropBlur: false,
                      child: ListTile(
                        title: Text(
                          tip.title,
                          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
                        ),
                        subtitle: Text(
                          tip.body,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.35),
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              GlassCard(
                useBackdropBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_outlined, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data portability',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF with charts & insights, or CSV for doctors and fertility consults.',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _exportingPdf ? null : _exportHealthPdf,
                            child: Text(_exportingPdf ? '…' : 'Export PDF'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _exportingCsv ? null : _exportCsv,
                            child: Text(_exportingCsv ? '…' : 'Copy CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Last 14 days — mood, energy, pain',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: GlassCard(
                  useBackdropBlur: false,
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: _MoodEnergyChart(
                    scheme: scheme,
                    series: series,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Hydration (glasses / day)',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: GlassCard(
                  useBackdropBlur: false,
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: _WaterBarChart(
                    scheme: scheme,
                    series: series,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Steps (from phone / watch)',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: GlassCard(
                  useBackdropBlur: false,
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: _StepsBarChart(
                    scheme: scheme,
                    series: series,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCustom(HealthLogService health) async {
    await health.addCustomSymptom(_customSx.text);
    _customSx.clear();
    if (mounted) setState(() {});
  }

  Widget _sliderRow(ColorScheme scheme, String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ($value / 5)',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _WearableSyncBanner extends StatelessWidget {
  const _WearableSyncBanner({
    required this.scheme,
    required this.wearable,
  });

  final ColorScheme scheme;
  final WearableHealthService wearable;

  @override
  Widget build(BuildContext context) {
    final last = wearable.lastSync;
    final subtitle = wearable.syncEnabled
        ? (last != null
            ? 'Last sync ${DateFormat.MMMd().add_jm().format(last)}'
            : 'Enabled — tap Sync to import steps, sleep & heart rate')
        : 'Off — enable in Settings → General → Wearables';

    return GlassCard(
      useBackdropBlur: false,
      child: Row(
        children: [
          Icon(Icons.watch_rounded, color: scheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wearable.platformLabel,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (wearable.syncEnabled)
            IconButton(
              tooltip: 'Sync now',
              onPressed: () async {
                final r = await wearable.syncRecentDays();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(r.userMessage(wearable.platformLabel))),
                );
              },
              icon: const Icon(Icons.sync_rounded),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.scheme,
    required this.label,
    required this.value,
    required this.icon,
  });

  final ColorScheme scheme;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodEnergyChart extends StatelessWidget {
  const _MoodEnergyChart({
    required this.scheme,
    required this.series,
  });

  final ColorScheme scheme;
  final List<(String, DailyHealthLog)> series;

  @override
  Widget build(BuildContext context) {
    final hasAny = series.any(
      (e) => e.$2.mood > 0 || e.$2.energy > 0 || e.$2.pain > 0,
    );
    if (!hasAny) {
      return Center(
        child: Text(
          'Save a few check-ins to see mood, energy & pain trends.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      );
    }

    final moodSpots = <FlSpot>[];
    final energySpots = <FlSpot>[];
    final painSpots = <FlSpot>[];
    for (var i = 0; i < series.length; i++) {
      final log = series[i].$2;
      if (log.mood > 0) moodSpots.add(FlSpot(i.toDouble(), log.mood.toDouble()));
      if (log.energy > 0) energySpots.add(FlSpot(i.toDouble(), log.energy.toDouble()));
      if (log.pain > 0) painSpots.add(FlSpot(i.toDouble(), log.pain.toDouble()));
    }

    final lineBarsData = <LineChartBarData>[
      if (moodSpots.isNotEmpty)
        LineChartBarData(
          spots: moodSpots,
          color: scheme.primary,
          barWidth: 3,
          isCurved: true,
          curveSmoothness: 0.3,
          dotData: const FlDotData(show: true),
        ),
      if (energySpots.isNotEmpty)
        LineChartBarData(
          spots: energySpots,
          color: scheme.tertiary,
          barWidth: 3,
          isCurved: true,
          curveSmoothness: 0.3,
          dotData: const FlDotData(show: true),
        ),
      if (painSpots.isNotEmpty)
        LineChartBarData(
          spots: painSpots,
          color: scheme.error,
          barWidth: 2,
          isCurved: true,
          curveSmoothness: 0.3,
          dotData: const FlDotData(show: true),
        ),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outline.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, m) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, m) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                final parts = series[i].$1.split('-');
                if (parts.length != 3) return const SizedBox.shrink();
                final d = int.tryParse(parts[2]);
                if (d == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: lineBarsData,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) {
              return touched.map((t) {
                final i = t.x.toInt();
                if (i < 0 || i >= series.length) return null;
                final line = t.bar.color;
                var name = 'Value';
                if (line == scheme.primary) name = 'Mood';
                if (line == scheme.tertiary) name = 'Energy';
                if (line == scheme.error) name = 'Pain';
                return LineTooltipItem(
                  '${series[i].$1}\n$name: ${t.y.toStringAsFixed(0)}',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              }).whereType<LineTooltipItem>().toList();
            },
          ),
        ),
      ),
    );
  }
}

class _StepsBarChart extends StatelessWidget {
  const _StepsBarChart({
    required this.scheme,
    required this.series,
  });

  final ColorScheme scheme;
  final List<(String, DailyHealthLog)> series;

  @override
  Widget build(BuildContext context) {
    final hasSteps = series.any((e) => e.$2.steps > 0);
    if (!hasSteps) {
      return Center(
        child: Text(
          'Turn on wearable sync in Settings to see daily steps here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: 12000,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 3000,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 3000,
              getTitlesWidget: (value, m) => Text(
                value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, m) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                final parts = series[i].$1.split('-');
                final d = parts.length == 3 ? int.tryParse(parts[2]) : null;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    d != null ? '$d' : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series[i].$2.steps.toDouble(),
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: scheme.primary.withValues(alpha: 0.8),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WaterBarChart extends StatelessWidget {
  const _WaterBarChart({
    required this.scheme,
    required this.series,
  });

  final ColorScheme scheme;
  final List<(String, DailyHealthLog)> series;

  @override
  Widget build(BuildContext context) {
    final hasWater = series.any((e) => e.$2.waterGlasses > 0);
    if (!hasWater) {
      return Center(
        child: Text(
          'Track glasses of water in your daily check-in to fill this chart.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: 12,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 3,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 3,
              getTitlesWidget: (value, m) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, m) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                final parts = series[i].$1.split('-');
                final d = parts.length == 3 ? int.tryParse(parts[2]) : null;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    d != null ? '$d' : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series[i].$2.waterGlasses.toDouble(),
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: scheme.tertiary.withValues(alpha: 0.85),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
