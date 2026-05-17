import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_log_service.dart';

/// Syncs steps, sleep, and heart rate from Apple Health (iOS) or Health Connect (Android).
class WearableHealthService extends ChangeNotifier {
  WearableHealthService._();
  static final WearableHealthService instance = WearableHealthService._();

  static const _kEnabled = 'wearable_sync_enabled';
  static const _kLastSyncMs = 'wearable_last_sync_ms';

  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE,
  ];

  bool _enabled = false;
  DateTime? _lastSync;
  bool _loaded = false;

  bool get syncEnabled => _enabled;
  DateTime? get lastSync => _lastSync;

  bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  String get platformLabel {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'Apple Health';
    if (defaultTargetPlatform == TargetPlatform.android) return 'Health Connect';
    return 'Wearables';
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _enabled = p.getBool(_kEnabled) ?? false;
    final ms = p.getInt(_kLastSyncMs);
    _lastSync = ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSyncEnabled(bool on) async {
    await ensureLoaded();
    _enabled = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, on);
    notifyListeners();
    if (on) {
      await syncRecentDays();
    }
  }

  /// Requests HealthKit / Health Connect read access.
  Future<bool> requestAccess() async {
    if (!isPlatformSupported) return false;
    try {
      final health = Health();
      await health.configure();
      return await health.requestAuthorization(_readTypes);
    } catch (e) {
      debugPrint('WearableHealthService.requestAccess: $e');
      return false;
    }
  }

  /// Pulls the last [days] calendar days into [HealthLogService].
  Future<WearableSyncResult> syncRecentDays({int days = 14}) async {
    await ensureLoaded();
    if (!isPlatformSupported) {
      return WearableSyncResult.unsupported;
    }
    if (!_enabled) {
      return WearableSyncResult.disabled;
    }

    try {
      final health = Health();
      await health.configure();

      var granted = await health.hasPermissions(_readTypes);
      if (granted != true) {
        granted = await health.requestAuthorization(_readTypes);
      }
      if (granted != true) {
        return WearableSyncResult.denied;
      }

      final end = DateTime.now();
      final startDay = DateTime(end.year, end.month, end.day).subtract(Duration(days: days - 1));
      final endQuery = end.add(const Duration(hours: 2));

      final points = await health.getHealthDataFromTypes(
        types: _readTypes,
        startTime: startDay,
        endTime: endQuery,
      );
      final cleaned = health.removeDuplicates(points);

      final stepsByDay = <String, int>{};
      final sleepMinutesByDay = <String, double>{};
      final hrSumByDay = <String, double>{};
      final hrCountByDay = <String, int>{};

      for (final p in cleaned) {
        final key = HealthLogService.dateKey(p.dateFrom.toLocal());
        final type = p.type;
        if (type == HealthDataType.STEPS) {
          stepsByDay[key] = (stepsByDay[key] ?? 0) + (p.value as num).round();
        } else if (type == HealthDataType.SLEEP_ASLEEP) {
          final mins = p.dateTo.difference(p.dateFrom).inMinutes;
          if (mins > 0) {
            sleepMinutesByDay[key] = (sleepMinutesByDay[key] ?? 0) + mins;
          }
        } else if (type == HealthDataType.RESTING_HEART_RATE ||
            type == HealthDataType.HEART_RATE) {
          final bpm = (p.value as num).round();
          if (bpm > 30 && bpm < 220) {
            hrSumByDay[key] = (hrSumByDay[key] ?? 0) + bpm;
            hrCountByDay[key] = (hrCountByDay[key] ?? 0) + 1;
          }
        }
      }

      var merged = 0;
      for (var i = 0; i < days; i++) {
        final d = startDay.add(Duration(days: i));
        final key = HealthLogService.dateKey(d);
        final steps = stepsByDay[key];
        final sleepMins = sleepMinutesByDay[key];
        final hrN = hrCountByDay[key];
        final hrAvg = hrN != null && hrN > 0 ? (hrSumByDay[key]! / hrN).round() : null;

        if (steps == null && sleepMins == null && hrAvg == null) continue;

        await HealthLogService.instance.mergeWearableForDay(
          key,
          steps: steps,
          sleepHours: sleepMins != null ? (sleepMins / 60).clamp(0.0, 24.0) : null,
          restingHeartRateBpm: hrAvg,
        );
        merged++;
      }

      _lastSync = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastSyncMs, _lastSync!.millisecondsSinceEpoch);
      notifyListeners();

      return merged > 0 ? WearableSyncResult.success : WearableSyncResult.empty;
    } catch (e) {
      debugPrint('WearableHealthService.syncRecentDays: $e');
      return WearableSyncResult.error;
    }
  }
}

enum WearableSyncResult {
  success,
  empty,
  denied,
  disabled,
  unsupported,
  error,
}

extension WearableSyncResultMessage on WearableSyncResult {
  String userMessage(String platformLabel) {
    switch (this) {
      case WearableSyncResult.success:
        return 'Synced sleep, steps, and heart rate from $platformLabel.';
      case WearableSyncResult.empty:
        return 'Connected, but no new data was found for the last two weeks.';
      case WearableSyncResult.denied:
        return 'Permission denied. Open $platformLabel settings and allow Glow to read your data.';
      case WearableSyncResult.disabled:
        return 'Turn on wearable sync in Settings first.';
      case WearableSyncResult.unsupported:
        return 'Wearable sync is available on the iOS and Android apps only.';
      case WearableSyncResult.error:
        return 'Sync failed. Check that $platformLabel is installed and try again.';
    }
  }
}
