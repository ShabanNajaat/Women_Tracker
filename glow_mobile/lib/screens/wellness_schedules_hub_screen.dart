import 'package:flutter/material.dart';

import '../models/wellness_schedule_type.dart';
import '../services/wellness_schedule_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';
import 'wellness_schedule_screen.dart';

/// Entry point for meal and workout schedulers.
class WellnessSchedulesHubScreen extends StatefulWidget {
  const WellnessSchedulesHubScreen({super.key});

  @override
  State<WellnessSchedulesHubScreen> createState() => _WellnessSchedulesHubScreenState();
}

class _WellnessSchedulesHubScreenState extends State<WellnessSchedulesHubScreen> {
  @override
  void initState() {
    super.initState();
    WellnessScheduleService.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const GlowPageAppBar(title: Text('Meals & workouts')),
      body: ListenableBuilder(
        listenable: WellnessScheduleService.instance,
        builder: (context, _) {
          final svc = WellnessScheduleService.instance;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Daily local reminders for nutrition and movement — tune them to your cycle and energy.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              for (final type in WellnessScheduleType.values) ...[
                _ScheduleTile(
                  scheme: scheme,
                  type: type,
                  active: svc.activeCount(type),
                  total: svc.reminders(type).length,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WellnessScheduleScreen(type: type),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              GlassCard(
                useBackdropBlur: false,
                child: Text(
                  svc.isSchedulingSupported
                      ? 'Reminders use separate channels from medication alerts. They repeat daily at the times you choose.'
                      : 'Schedules work on iOS and Android — open the mobile app to enable notifications.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.scheme,
    required this.type,
    required this.active,
    required this.total,
    required this.onTap,
  });

  final ColorScheme scheme;
  final WellnessScheduleType type;
  final int active;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBackdropBlur: false,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(type.icon, color: scheme.primary, size: 32),
        title: Text(
          type.screenTitle,
          style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
        ),
        subtitle: Text(
          total == 0
              ? 'No reminders — tap to add'
              : '$active active · $total scheduled',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
