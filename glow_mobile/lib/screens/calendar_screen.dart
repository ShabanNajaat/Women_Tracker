import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/cycle_service.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/glow_page_app_bar.dart';
import '../widgets/fertility_prediction_cards.dart';
import '../widgets/glass_card.dart';
import '../models/fertility_intent.dart';
import 'journal_screen.dart';

/// Full calendar with next-period estimate (local). Wrapped in [AppBackdrop] when pushed from Her Cycle.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.embedded = true});

  /// When false (e.g. pushed route), paints a solid themed backdrop so light/dark matches the rest of the app.
  final bool embedded;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _periodDays = {};
  bool _ready = false;

  void _syncPeriodHighlight() {
    if (!mounted) return;
    final c = CycleService.instance;
    setState(() {
      _periodDays
        ..clear()
        ..addAll(
          c.periodStarts.map((s) => DateTime(s.year, s.month, s.day)),
        );
    });
  }

  @override
  void initState() {
    super.initState();
    CycleService.instance.addListener(_syncPeriodHighlight);
    _load();
  }

  @override
  void dispose() {
    CycleService.instance.removeListener(_syncPeriodHighlight);
    super.dispose();
  }

  Future<void> _load() async {
    await CycleService.instance.ensureLoaded();
    if (!mounted) return;
    final c = CycleService.instance;
    setState(() {
      _ready = true;
      _periodDays
        ..clear()
        ..addAll(
          c.periodStarts.map((s) => DateTime(s.year, s.month, s.day)),
        );
    });
  }

  bool _isPredictedDay(DateTime date, CycleService c) {
    final next = c.predictedNextPeriodStart;
    if (next == null) return false;
    final d0 = DateTime(date.year, date.month, date.day);
    for (var i = 0; i < 4; i++) {
      final p =
          DateTime(next.year, next.month, next.day).add(Duration(days: i));
      if (d0.year == p.year && d0.month == p.month && d0.day == p.day) {
        return true;
      }
    }
    return false;
  }

  Future<void> _markPeriodStartToday() async {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    await CycleService.instance.setLastPeriodStart(d);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Period start saved. Predictions updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = CycleService.instance;

    final body = !_ready
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cycle Calendar',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedDay),
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap a day when your period started. Log 3+ starts (months apart) and Glow learns your average cycle length.',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    FertilityPredictionCards(cycle: c, scheme: scheme),
                    if (c.learning.isIrregular && c.hasCycleAnchor) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Your recent cycles vary more than usual — fertile and period estimates may be less accurate.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (c.periodStarts.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _CycleLearningCard(cycle: c, scheme: scheme),
                    ],
                    const SizedBox(height: 20),
                    GlassCard(
                      useBackdropBlur: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chevron_left,
                                    color: scheme.onSurface),
                                onPressed: () {
                                  setState(() {
                                    _focusedDay = DateTime(_focusedDay.year,
                                        _focusedDay.month - 1);
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right,
                                    color: scheme.onSurface),
                                onPressed: () {
                                  setState(() {
                                    _focusedDay = DateTime(_focusedDay.year,
                                        _focusedDay.month + 1);
                                  });
                                },
                              ),
                            ],
                          ),
                          _buildDaysOfWeek(scheme),
                          const SizedBox(height: 16),
                          _buildCalendarGrid(scheme, c),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLegend(scheme),
                    if (c.hasCycleAnchor) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.fertilityIntent.calendarDisclaimer,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (c.hasCycleAnchor)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () async {
                            await CycleService.instance.clearLastPeriodStart();
                            await _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Period start cleared. Tap a day when you want a new estimate.'),
                                ),
                              );
                            }
                          },
                          child: const Text('Clear period start'),
                        ),
                      ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: _markPeriodStartToday,
                      icon: Icon(Icons.water_drop_outlined,
                          color: scheme.primary),
                      label: const Text('Mark period started today'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const JournalScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Log Symptoms',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const GlowPageAppBar(title: Text('Cycle Calendar')),
      body: AppBackdrop(
        child: body,
      ),
    );
  }

  Widget _buildDaysOfWeek(ColorScheme scheme) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map(
            (day) => Text(
              day,
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontWeight: FontWeight.bold,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(ColorScheme scheme, CycleService c) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth + firstWeekday - 1,
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) return const SizedBox();
        final day = index - firstWeekday + 2;
        final date = DateTime(_focusedDay.year, _focusedDay.month, day);
        final isToday = day == DateTime.now().day &&
            _focusedDay.month == DateTime.now().month &&
            _focusedDay.year == DateTime.now().year;
        final clean = DateTime(date.year, date.month, date.day);
        final isPeriod = c.isLoggedPeriodStart(clean);
        final isLatestPeriod = c.lastPeriodStart != null &&
            clean.year == c.lastPeriodStart!.year &&
            clean.month == c.lastPeriodStart!.month &&
            clean.day == c.lastPeriodStart!.day;
        final isPredicted = _isPredictedDay(date, c);
        final isOvulation = c.isEstimatedOvulationDay(clean) && !isPeriod;
        final isFertile = c.isDateInApproximateFertileWindow(clean) && !isPeriod && !isPredicted;

        final emphasizeFertile = c.fertilityIntent == FertilityIntent.avoidPregnancy;
        final Color cellBg = isPeriod
            ? (isLatestPeriod
                ? scheme.primary.withValues(alpha: 0.42)
                : scheme.primary.withValues(alpha: 0.22))
            : isOvulation
                ? scheme.tertiary.withValues(alpha: 0.45)
            : isPredicted
                ? scheme.secondary.withValues(alpha: 0.22)
                : isFertile
                    ? (emphasizeFertile
                        ? scheme.error.withValues(alpha: 0.2)
                        : scheme.tertiary.withValues(alpha: 0.32))
                    : scheme.surfaceContainerLow.withValues(alpha: 0.65);

        return GestureDetector(
          onTap: () async {
            await CycleService.instance.setLastPeriodStart(clean);
            if (!mounted) return;
            final svc = CycleService.instance;
            final extra = svc.personalizedPredictionCaption;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  extra != null
                      ? 'Saved ${DateFormat.MMMd().format(clean)}. $extra'
                      : 'Period start set to ${DateFormat.MMMd().format(clean)}. Log more past starts to personalize.',
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: cellBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isToday
                    ? scheme.primary
                    : isOvulation
                        ? scheme.tertiary
                    : isPredicted && !isPeriod
                        ? scheme.secondary.withValues(alpha: 0.9)
                        : isFertile
                            ? (emphasizeFertile
                                ? scheme.error.withValues(alpha: 0.85)
                                : scheme.tertiary.withValues(alpha: 0.88))
                            : scheme.outline.withValues(alpha: 0.2),
                width: isToday ||
                        isOvulation ||
                        (isPredicted && !isPeriod) ||
                        isFertile
                    ? 2
                    : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isPeriod ? scheme.onPrimary : scheme.onSurface,
                  fontWeight:
                      isToday || isPeriod ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(ColorScheme scheme) {
    final c = CycleService.instance;
    final items = <Widget>[
      _legendItem(scheme, scheme.primary, 'Latest period start'),
      _legendItem(scheme, scheme.primary.withValues(alpha: 0.5), 'Earlier logged starts'),
      _legendItem(scheme, scheme.secondary, 'Predicted period window'),
    ];
    if (c.fertilityIntent == FertilityIntent.ttc) {
      items.add(_legendItem(scheme, scheme.tertiary, 'Estimated ovulation day'));
    }
  final fertileColor = c.fertilityIntent == FertilityIntent.avoidPregnancy
        ? scheme.error.withValues(alpha: 0.75)
        : scheme.tertiary;
    items.add(_legendItem(
      scheme,
      fertileColor,
      c.fertilityIntent == FertilityIntent.avoidPregnancy
          ? 'Higher-fertility band (estimate)'
          : 'Approx. fertile band (estimate)',
    ));
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _legendItem(ColorScheme scheme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
      ],
    );
  }
}

class _CycleLearningCard extends StatelessWidget {
  const _CycleLearningCard({required this.cycle, required this.scheme});

  final CycleService cycle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final learn = cycle.learning;
    final intervals = learn.validIntervals;

    return GlassCard(
      useBackdropBlur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: scheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Your cycle pattern',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  learn.confidenceLabel,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${learn.periodStartsLogged} period start${learn.periodStartsLogged == 1 ? '' : 's'} logged'
            '${intervals.isEmpty ? '' : ' · ${intervals.length} measured cycle${intervals.length == 1 ? '' : 's'}'}',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (intervals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Lengths: ${intervals.join(', ')} days'
              '${learn.averageCycleLength != null ? ' → average ${learn.averageCycleLength} days' : ''}',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (learn.periodStartsLogged < 3) ...[
            const SizedBox(height: 8),
            Text(
              'Tip: log when your period started on 2–3 earlier months (tap each start day) to unlock a personalized prediction.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
