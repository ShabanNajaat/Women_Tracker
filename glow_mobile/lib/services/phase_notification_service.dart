import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/cycle_phase.dart';
import 'cycle_service.dart';
import 'glow_notification_service.dart';

/// Phase-aware local reminders (hydration, stretch, rest).
class PhaseNotificationService {
  PhaseNotificationService._();
  static final PhaseNotificationService instance = PhaseNotificationService._();

  static const _prefHydration = 'glow_phase_notif_hydration';
  static const _prefStretch = 'glow_phase_notif_stretch';
  static const _prefRest = 'glow_phase_notif_rest';
  static const _channelId = 'glow_phase_care';
  static const _idHydration = 91011;
  static const _idStretch = 91012;
  static const _idRest = 91013;

  Future<bool> hydrationEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefHydration) ?? false;
  }

  Future<bool> stretchEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefStretch) ?? false;
  }

  Future<bool> restEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefRest) ?? false;
  }

  Future<void> setHydration(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefHydration, v);
    await reschedule();
  }

  Future<void> setStretch(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefStretch, v);
    await reschedule();
  }

  Future<void> setRest(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefRest, v);
    await reschedule();
  }

  Future<void> reschedule() async {
    if (kIsWeb) return;
    await GlowNotificationService.instance.requestPermissionsIfNeeded();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(_idHydration);
    await plugin.cancel(_idStretch);
    await plugin.cancel(_idRest);

    await CycleService.instance.ensureLoaded();
    final phase = CycleService.instance.phaseForDay(
      CycleService.instance.currentDayInCycle,
      cycleLength: CycleService.instance.typicalCycleLength,
    );

    final hydrate = await hydrationEnabled();
    final stretch = await stretchEnabled();
    final rest = await restEnabled();

    if (hydrate && (phase == CyclePhase.menstrual || phase == CyclePhase.luteal)) {
      await _schedule(
        id: _idHydration,
        hour: 11,
        title: 'Hydration reminder',
        body: phase == CyclePhase.menstrual
            ? 'Heavy flow days need extra fluids — take a few sips now.'
            : 'Stay ahead of PMS fatigue with a glass of water.',
      );
    }

    if (stretch && phase == CyclePhase.luteal) {
      await _schedule(
        id: _idStretch,
        hour: 18,
        title: 'Stretch & relax',
        body: 'Your luteal phase is a good time for gentle yoga or hip openers — 10 minutes is enough.',
      );
    }

    if (rest && phase == CyclePhase.menstrual) {
      await _schedule(
        id: _idRest,
        hour: 21,
        title: 'Wind down',
        body: 'Menstrual days: prioritize rest. Dim screens and try a warm shower when you can.',
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required int hour,
    required String title,
    required String body,
  }) async {
    tzdata.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final plugin = FlutterLocalNotificationsPlugin();
    final android = AndroidNotificationDetails(
      _channelId,
      'Phase care reminders',
      channelDescription: 'Cycle-phase hydration, stretch, and rest nudges',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(android: android, iOS: const DarwinNotificationDetails());
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
