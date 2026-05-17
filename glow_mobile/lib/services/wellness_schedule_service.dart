import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/scheduled_reminder.dart';
import '../models/wellness_schedule_type.dart';
import 'glow_notification_service.dart';
import 'user_data_scope.dart';

/// Local meal and workout daily reminders (device scheduling only).
class WellnessScheduleService extends ChangeNotifier {
  WellnessScheduleService._();
  static final WellnessScheduleService instance = WellnessScheduleService._();

  static const _kBlob = 'glow_wellness_schedules_v1';
  static const _maxPerType = 16;

  final List<ScheduledReminder> _items = [];
  bool _loaded = false;
  bool _tzReady = false;

  bool get isSchedulingSupported => !kIsWeb;

  void invalidate() {
    _loaded = false;
    _items.clear();
    notifyListeners();
  }

  List<ScheduledReminder> reminders(WellnessScheduleType type) =>
      List.unmodifiable(_items.where((e) => e.type == type));

  int activeCount(WellnessScheduleType type) =>
      _items.where((e) => e.type == type && e.enabled).length;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final kBlob = await UserDataScope.scopedKey(_kBlob);
    final raw = p.getString(kBlob);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final list in decoded.values) {
            if (list is List) {
              for (final e in list) {
                if (e is Map<String, dynamic>) {
                  _items.add(ScheduledReminder.fromJson(e));
                }
              }
            }
          }
        } else if (decoded is List) {
          for (final e in decoded) {
            if (e is Map<String, dynamic>) {
              _items.add(ScheduledReminder.fromJson(e));
            }
          }
        }
      } catch (_) {}
    }
    _sortItems();
    _loaded = true;
    notifyListeners();
  }

  void _sortItems() {
    _items.sort((a, b) {
      final tc = a.type.index.compareTo(b.type.index);
      if (tc != 0) return tc;
      if (a.hour != b.hour) return a.hour.compareTo(b.hour);
      return a.minute.compareTo(b.minute);
    });
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    final out = <String, dynamic>{
      for (final t in WellnessScheduleType.values)
        t.prefsKey: _items.where((e) => e.type == t).map((e) => e.toJson()).toList(),
    };
    final kBlob = await UserDataScope.scopedKey(_kBlob);
    await p.setString(kBlob, jsonEncode(out));
    notifyListeners();
  }

  int _allocateNotificationId(WellnessScheduleType type) {
    final base = type.notifIdBase;
    final used = _items.map((e) => e.notificationId).toSet();
    for (var i = 0; i < 150; i++) {
      final id = base + i;
      if (!used.contains(id)) return id;
    }
    return base + DateTime.now().millisecondsSinceEpoch % 10000;
  }

  Future<void> rescheduleAll() async {
    if (!isSchedulingSupported) return;
    await ensureLoaded();
    await GlowNotificationService.instance.init();
    await _ensureTimeZone();
    final plugin = FlutterLocalNotificationsPlugin();

    for (final r in _items) {
      await plugin.cancel(r.notificationId);
    }

    for (final r in _items) {
      if (r.enabled) {
        await _scheduleOne(plugin, r);
      }
    }
  }

  Future<void> _ensureTimeZone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _tzReady = true;
  }

  Future<void> _scheduleOne(FlutterLocalNotificationsPlugin plugin, ScheduledReminder r) async {
    final meta = r.type;
    final android = AndroidNotificationDetails(
      meta.channelId,
      meta.channelTitle,
      channelDescription: meta.channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(
      android: android,
      iOS: const DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, r.hour, r.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = r.note != null && r.note!.trim().isNotEmpty
        ? r.note!.trim()
        : meta.defaultNotificationBody;

    await plugin.zonedSchedule(
      r.notificationId,
      r.name,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<bool> requestNotificationPermission() async {
    if (!isSchedulingSupported) return false;
    await GlowNotificationService.instance.requestPermissionsIfNeeded();
    return true;
  }

  Future<ScheduledReminder?> add({
    required WellnessScheduleType type,
    required String name,
    required int hour,
    required int minute,
    String? note,
    bool enabled = true,
  }) async {
    await ensureLoaded();
    if (_items.where((e) => e.type == type).length >= _maxPerType) return null;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final item = ScheduledReminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      name: trimmed.length > 48 ? '${trimmed.substring(0, 48)}…' : trimmed,
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
      enabled: enabled,
      notificationId: _allocateNotificationId(type),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    _items.add(item);
    _sortItems();
    await _persist();
    await rescheduleAll();
    return item;
  }

  Future<void> update(ScheduledReminder updated) async {
    await ensureLoaded();
    final i = _items.indexWhere((e) => e.id == updated.id);
    if (i < 0) return;
    _items[i] = updated;
    _sortItems();
    await _persist();
    await rescheduleAll();
  }

  Future<void> delete(String id) async {
    await ensureLoaded();
    final removed = _items.where((e) => e.id == id).toList();
    _items.removeWhere((e) => e.id == id);
    await _persist();
    if (isSchedulingSupported && removed.isNotEmpty) {
      final plugin = FlutterLocalNotificationsPlugin();
      for (final r in removed) {
        await plugin.cancel(r.notificationId);
      }
    }
    notifyListeners();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await ensureLoaded();
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(enabled: enabled);
    await _persist();
    await rescheduleAll();
  }

  /// Suggested meal times for first-time setup (does not duplicate existing names).
  Future<int> applyMealStarterPack() async {
    await ensureLoaded();
    const defaults = [
      (8, 0, 'Breakfast'),
      (12, 30, 'Lunch'),
      (18, 30, 'Dinner'),
    ];
    var added = 0;
    final existing = reminders(WellnessScheduleType.meal).map((e) => e.name.toLowerCase()).toSet();
    for (final d in defaults) {
      if (existing.contains(d.$3.toLowerCase())) continue;
      if (_items.where((e) => e.type == WellnessScheduleType.meal).length >= _maxPerType) break;
      final r = await add(
        type: WellnessScheduleType.meal,
        name: d.$3,
        hour: d.$1,
        minute: d.$2,
      );
      if (r != null) added++;
    }
    return added;
  }
}
