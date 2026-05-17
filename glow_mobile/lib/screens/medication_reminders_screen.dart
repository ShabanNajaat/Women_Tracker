import 'package:flutter/material.dart';

import '../models/medication_reminder.dart';
import '../services/medication_reminder_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

/// Manage local medication / supplement / birth-control reminders.
class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() => _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  static const _quickAdd = [
  'Birth control',
  'Pain relief',
  'Iron supplement',
  'Magnesium',
  'Prenatal vitamin',
  ];

  @override
  void initState() {
    super.initState();
    MedicationReminderService.instance.ensureLoaded();
  }

  Future<void> _openEditor({MedicationReminder? existing}) async {
    final svc = MedicationReminderService.instance;
    if (!svc.isSchedulingSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication reminders are available on the iOS and Android apps.'),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var hour = existing?.hour ?? 9;
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
                    existing == null ? 'New reminder' : 'Edit reminder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Birth control, Ibuprofen',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'Take with food',
                      border: OutlineInputBorder(),
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
                    children: _quickAdd.map((label) {
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
        name: nameCtrl.text,
        hour: hour,
        minute: minute,
        note: noteCtrl.text,
      );
      if (!mounted) return;
      if (added == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add — maximum reminders reached.')),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final svc = MedicationReminderService.instance;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const GlowPageAppBar(title: Text('Medication reminders')),
      body: ListenableBuilder(
        listenable: svc,
        builder: (context, _) {
          final items = svc.reminders;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text(
                svc.isSchedulingSupported
                    ? 'Local reminders on this device — not a prescription manager. Always follow your clinician’s instructions.'
                    : 'Open Glow on your phone to schedule medication reminders.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    children: [
                      Icon(Icons.medication_outlined, size: 48, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'No reminders yet',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add birth control, pain relief, iron, or any supplement you want a gentle nudge for.',
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
                        trailing: Switch(
                          value: r.enabled,
                          onChanged: svc.isSchedulingSupported
                              ? (v) => svc.setEnabled(r.id, v)
                              : null,
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
        label: const Text('Add reminder'),
      ),
    );
  }
}
