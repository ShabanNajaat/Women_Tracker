import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/body_region.dart';
import '../services/health_log_service.dart';
import '../widgets/body_pain_silhouette.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

/// Tap body zones to log mild / moderate / severe discomfort for today.
class BodyPainMapScreen extends StatefulWidget {
  const BodyPainMapScreen({super.key});

  @override
  State<BodyPainMapScreen> createState() => _BodyPainMapScreenState();
}

class _BodyPainMapScreenState extends State<BodyPainMapScreen> {
  bool _backView = false;
  DateTime _day = DateTime.now();

  bool get _isToday {
    final n = DateTime.now();
    return _day.year == n.year && _day.month == n.month && _day.day == n.day;
  }

  @override
  void initState() {
    super.initState();
    HealthLogService.instance.ensureLoaded();
  }

  Map<String, int> _painForDay(HealthLogService health) =>
      Map<String, int>.from(health.bodyPainForDate(_day));

  Future<void> _shiftDay(int delta) async {
    final next = DateTime(_day.year, _day.month, _day.day).add(Duration(days: delta));
    final today = DateTime.now();
    if (next.isAfter(DateTime(today.year, today.month, today.day))) return;
    setState(() => _day = next);
  }

  Future<void> _onRegionTap(String regionId) async {
    if (!_isToday) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Body map edits are for today — use the arrows to review past days.'),
          ),
        );
      }
      return;
    }
    await HealthLogService.instance.cycleBodyRegionToday(regionId);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat.yMMMEd().format(_day);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const GlowPageAppBar(title: Text('Body pain map')),
      body: ListenableBuilder(
        listenable: HealthLogService.instance,
        builder: (context, _) {
          final health = HealthLogService.instance;
          final pain = _painForDay(health);
          final active = pain.entries.where((e) => e.value > 0).toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Tap a zone to cycle mild → moderate → severe → clear. For wellness tracking only.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftDay(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous day',
                  ),
                  Expanded(
                    child: Text(
                      dateLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isToday ? null : () => _shiftDay(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next day',
                  ),
                ],
              ),
              if (!_isToday)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Viewing a past day (read-only).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.tertiary, fontSize: 12),
                  ),
                ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Front'), icon: Icon(Icons.person_outline)),
                  ButtonSegment(value: true, label: Text('Back'), icon: Icon(Icons.person_outline)),
                ],
                selected: {_backView},
                onSelectionChanged: (s) => setState(() => _backView = s.first),
              ),
              const SizedBox(height: 12),
              _IntensityLegend(scheme: scheme),
              const SizedBox(height: 8),
              GlassCard(
                useBackdropBlur: false,
                padding: const EdgeInsets.all(12),
                child: BodyPainSilhouette(
                  backView: _backView,
                  painLevels: pain,
                  onRegionTap: _onRegionTap,
                ),
              ),
              const SizedBox(height: 16),
              if (active.isEmpty)
                Text(
                  'No zones marked${_isToday ? ' — tap the figure above' : ' on this day'}.',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                )
              else ...[
                Text(
                  'Marked today',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    children: [
                      for (final e in active) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            BodyRegions.byId(e.key)?.label ?? e.key,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LevelChip(level: e.value, scheme: scheme),
                              if (_isToday) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  tooltip: 'Clear zone',
                                  onPressed: () =>
                                      HealthLogService.instance.clearBodyRegionToday(e.key),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (e != active.last) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ],
              if (_isToday && active.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => HealthLogService.instance.clearBodyPainToday(),
                  icon: const Icon(Icons.layers_clear_outlined),
                  label: const Text('Clear all zones for today'),
                ),
              ],
              const SizedBox(height: 20),
              _WeeklyHotspotsCard(scheme: scheme, health: health),
            ],
          );
        },
      ),
    );
  }
}

class _IntensityLegend extends StatelessWidget {
  const _IntensityLegend({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    Widget dot(int level, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: level == 0
                  ? scheme.primary.withValues(alpha: 0.08)
                  : Color.lerp(
                      scheme.surfaceContainerHigh,
                      scheme.error,
                      0.25 + (level / BodyPainLevel.severe) * 0.65,
                    ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        dot(0, 'Clear'),
        dot(BodyPainLevel.mild, 'Mild'),
        dot(BodyPainLevel.moderate, 'Moderate'),
        dot(BodyPainLevel.severe, 'Severe'),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.scheme});

  final int level;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        BodyPainLevel.label(level),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _WeeklyHotspotsCard extends StatelessWidget {
  const _WeeklyHotspotsCard({required this.scheme, required this.health});

  final ColorScheme scheme;
  final HealthLogService health;

  @override
  Widget build(BuildContext context) {
    final hotspots = health.bodyPainHotspotsLastDays(7);
    if (hotspots.isEmpty) {
      return GlassCard(
        useBackdropBlur: false,
        child: Text(
          'Log a few days to see which areas show up most often this week.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
      );
    }

    final top = hotspots.take(4).toList();
    return GlassCard(
      useBackdropBlur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-day hotspots',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zones logged on multiple days — useful for cycle or flare patterns.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          ...top.map((e) {
            final def = BodyRegions.byId(e.regionId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      def?.label ?? e.regionId,
                      style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                    ),
                  ),
                  Text(
                    '${e.dayCount}d · avg ${e.avgLevel.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
