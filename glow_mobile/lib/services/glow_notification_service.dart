import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local daily wellness reminder (9:00 device time). Not a remote push provider.
class GlowNotificationService {
  GlowNotificationService._();
  static final GlowNotificationService instance = GlowNotificationService._();

  static const _prefEnabled = 'glow_local_notifications_enabled';
  static const _channelId = 'glow_wellness_digest';
  static const _notifId = 91001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> getEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefEnabled) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefEnabled, enabled);
    if (!kIsWeb) {
      if (enabled) {
        await _ensureInit();
        if (defaultTargetPlatform == TargetPlatform.android) {
          final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          await android?.requestNotificationsPermission();
        }
        await _scheduleDaily();
      } else {
        await _plugin.cancel(_notifId);
      }
    }
  }

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    await _ensureInit();
    if (await getEnabled()) {
      await _scheduleDaily();
    }
  }

  /// Call before scheduling medication or other local alerts.
  Future<void> requestPermissionsIfNeeded() async {
    if (kIsWeb) return;
    await _ensureInit();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  Future<void> _ensureInit() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    tzdata.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _scheduleDaily() async {
    await _configureLocalTimeZone();
    final android = AndroidNotificationDetails(
      _channelId,
      'Wellness reminders',
      channelDescription: 'Gentle Glow check-ins',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(android: android, iOS: const DarwinNotificationDetails());
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _notifId,
      'Your Glow check-in',
      'Pause for a breath — how is your body feeling today?',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
