import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/wearable_health_service.dart';

/// Settings block for Apple Health / Health Connect sync.
class WearableSettingsSection extends StatefulWidget {
  const WearableSettingsSection({super.key, required this.scheme});

  final ColorScheme scheme;

  @override
  State<WearableSettingsSection> createState() => _WearableSettingsSectionState();
}

class _WearableSettingsSectionState extends State<WearableSettingsSection> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WearableHealthService.instance.ensureLoaded();
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final w = WearableHealthService.instance;
    final result = await w.syncRecentDays();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.userMessage(w.platformLabel))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final w = WearableHealthService.instance;

    return ListenableBuilder(
      listenable: w,
      builder: (context, _) {
        if (!w.isPlatformSupported) {
          return Text(
            'Wearable sync (Apple Health / Health Connect) is available in the iOS and Android apps. '
            'Use the mobile app to import steps, sleep, and heart rate.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        final last = w.lastSync;
        final lastLabel = last != null
            ? DateFormat('MMM d, h:mm a').format(last)
            : 'Never';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Sync from ${w.platformLabel}',
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Import steps, sleep, and heart rate into Health insights (read-only).',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              value: w.syncEnabled,
              onChanged: _syncing
                  ? null
                  : (on) async {
                      await w.setSyncEnabled(on);
                      if (!mounted) return;
                      if (on) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Allow Glow to read your data when ${w.platformLabel} asks.',
                            ),
                          ),
                        );
                      }
                    },
            ),
            Text(
              'Last sync: $lastLabel',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _syncing || !w.syncEnabled ? null : _syncNow,
                  icon: _syncing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 20),
                  label: Text(_syncing ? 'Syncing…' : 'Sync now'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _syncing
                      ? null
                      : () async {
                          await w.requestAccess();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'If the permission sheet did not appear, open ${w.platformLabel} and enable read access for Glow.',
                              ),
                            ),
                          );
                        },
                  child: const Text('Permissions'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'On iPhone: Settings → Health → Data Access → Glow. '
              'On Android: install Health Connect, then grant read access for steps, sleep, and heart rate.',
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
