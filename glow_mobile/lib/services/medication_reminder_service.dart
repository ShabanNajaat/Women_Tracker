import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication_reminder.dart';
import 'glow_notification_service.dart';
import 'user_data_scope.dart';

/// Local medication / supplement reminders (device scheduling only).
class MedicationReminderService extends ChangeNotifier {
  MedicationReminderService._();
  static final MedicationReminderService instance = MedicationReminderService._();

  static const _kBlob = 'glow_medication_reminders_v1';
  static const _notifIdBase = 92000;
  static const _channelId = 'glow_medication_reminders';
  static const _maxReminders = 24;

  final List<MedicationReminder> _items = [];
  bool _loaded = false;
  bool _tzReady = false;

  List<MedicationReminder> get reminders => List.unmodifiable(_items);

  bool get isSchedulingSupported => !kIsWeb;

  void invalidate() {
    _loaded = false;
    _items.clear();
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final kBlob = await UserDataScope.scopedKey(_kBlob);
    final raw = p.getString(kBlob);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final e in list) {
            if (e is Map<String, dynamic>) {
              _items.add(MedicationReminder.fromJson(e));
            }
          }
        }
      } catch (_) {}
    }
    _items.sort((a, b) => a.hour != b.hour ? a.hour.compareTo(b.hour) : a.minute.compareTo(b.minute));
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    final kBlob = await UserDataScope.scopedKey(_kBlob);
    await p.setString(
      kBlob,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  int _allocateNotificationId() {
    final used = _items.map((e) => e.notificationId).toSet();
    for (var i = 0; i < 200; i++) {
      final id = _notifIdBase + i;
      if (!used.contains(id)) return id;
    }
    return _notifIdBase + DateTime.now().millisecondsSinceEpoch % 10000;
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

  Future<void> _scheduleOne(FlutterLocalNotificationsPlugin plugin, MedicationReminder r) async {
    final android = AndroidNotificationDetails(
      _channelId,
      'Medication reminders',
      channelDescription: 'Reminders for meds, supplements, and birth control',
      importance: Importance.high,
      priority: Priority.high,
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
        : 'Time for your scheduled dose — tap to open Glow.';

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

  Future<MedicationReminder?> add({
    required String name,
    required int hour,
    required int minute,
    String? note,
    bool enabled = true,
  }) async {
    await ensureLoaded();
    if (_items.length >= _maxReminders) return null;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final item = MedicationReminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed.length > 48 ? '${trimmed.substring(0, 48)}…' : trimmed,
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
      enabled: enabled,
      notificationId: _allocateNotificationId(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    _items.add(item);
    _items.sort((a, b) => a.hour != b.hour ? a.hour.compareTo(b.hour) : a.minute.compareTo(b.minute));
    await _persist();
    await rescheduleAll();
    return item;
  }

  Future<void> update(MedicationReminder updated) async {
    await ensureLoaded();
    final i = _items.indexWhere((e) => e.id == updated.id);
    if (i < 0) return;
    _items[i] = updated;
    _items.sort((a, b) => a.hour != b.hour ? a.hour.compareTo(b.hour) : a.minute.compareTo(b.minute));
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
}
