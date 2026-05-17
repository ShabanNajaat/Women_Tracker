import 'package:flutter/material.dart';

import '../models/scheduled_reminder.dart';
import '../models/wellness_schedule_type.dart';
import '../services/wellness_schedule_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

/// Manage local meal or workout reminders.
class WellnessScheduleScreen extends StatefulWidget {
  const WellnessScheduleScreen({super.key, required this.type});

  final WellnessScheduleType type;

  @override
  State<WellnessScheduleScreen> createState() => _WellnessScheduleScreenState();
}

class _WellnessScheduleScreenState extends State<WellnessScheduleScreen> {
  WellnessScheduleType get type => widget.type;

  @override
  void initState() {
    super.initState();
    WellnessScheduleService.instance.ensureLoaded();
  }

  Future<void> _openEditor({ScheduledReminder? existing}) async {
    final svc = WellnessScheduleService.instance;
    if (!svc.isSchedulingSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedules are available on the iOS and Android apps.'),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var hour = existing?.hour ?? (type == WellnessScheduleType.meal ? 8 : 7);
    var minute = existing?.minute ?? 0;

    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'New ${type.title.toLowerCase()} reminder' : 'Edit reminder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: type == WellnessScheduleType.meal ? 'e.g. Lunch' : 'e.g. Morning yoga',
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: type == WellnessScheduleType.meal
                          ? 'Protein + greens'
                          : '20 min, gentle',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(hour: hour, minute: minute),
                      );
                      if (picked != null) {
                        setModalState(() {
                          hour = picked.hour;
                          minute = picked.minute;
                        });
                      }
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      'Time: ${TimeOfDay(hour: hour, minute: minute).format(ctx)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: type.quickAdd.map((label) {
                      return ActionChip(
                        label: Text(label),
                        onPressed: () => nameCtrl.text = label,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: Text(existing == null ? 'Add reminder' : 'Save changes'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (saved != true || !mounted) return;

    await svc.requestNotificationPermission();

    if (existing == null) {
      final added = await svc.add(
        type: type,
        name: nameCtrl.text,
        hour: hour,
        minute: minute,
        note: noteCtrl.text,
      );
      if (!mounted) return;
      if (added == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add — maximum reminders reached for this type.')),
        );
      }
    } else {
      await svc.update(
        existing.copyWith(
          name: nameCtrl.text.trim(),
          hour: hour,
          minute: minute,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        ),
      );
    }
  }

  Future<void> _applyStarterPack() async {
    if (type != WellnessScheduleType.meal) return;
    final n = await WellnessScheduleService.instance.applyMealStarterPack();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n > 0 ? 'Added $n meal reminders (Breakfast, Lunch, Dinner).' : 'Meal times already set up.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final svc = WellnessScheduleService.instance;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: GlowPageAppBar(title: Text(type.screenTitle)),
      body: ListenableBuilder(
        listenable: svc,
        builder: (context, _) {
          final items = svc.reminders(type);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text(
                svc.isSchedulingSupported
                    ? 'Daily local nudges on this device — adjust for your cycle phase and energy. Not medical advice.'
                    : 'Open Glow on your phone to schedule ${type.title.toLowerCase()} reminders.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (type == WellnessScheduleType.meal && items.isEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: svc.isSchedulingSupported ? _applyStarterPack : null,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Quick setup: Breakfast, Lunch, Dinner'),
                ),
              ],
              const SizedBox(height: 16),
              if (items.isEmpty)
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    children: [
                      Icon(type.icon, size: 48, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'No ${type.title.toLowerCase()} reminders yet',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.emptyHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...items.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      useBackdropBlur: false,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.alarm_rounded, color: scheme.onPrimaryContainer),
                        ),
                        title: Text(
                          r.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${r.timeLabel}${r.note != null ? ' · ${r.note}' : ''}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: r.enabled,
                              onChanged: svc.isSchedulingSupported
                                  ? (v) => svc.setEnabled(r.id, v)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete reminder?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) await svc.delete(r.id);
                              },
                            ),
                          ],
                        ),
                        onTap: () => _openEditor(existing: r),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_alarm_rounded),
        label: Text('Add ${type.title.toLowerCase()}'),
      ),
    );
  }
}
