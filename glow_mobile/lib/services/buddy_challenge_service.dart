import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/buddy_challenge_type.dart';
import 'health_log_service.dart';
import 'partner_service.dart';
import 'user_data_scope.dart';

/// 7-day supportive micro-challenges with optional partner cheer (not competitive).
class BuddyChallengeService {
  BuddyChallengeService._();
  static final BuddyChallengeService instance = BuddyChallengeService._();

  static const _kActive = 'glow_buddy_challenge_active';
  static const _kDone = 'glow_buddy_challenge_done'; // kind:date,date,...

  static final ValueNotifier<int> revision = ValueNotifier(0);

  BuddyChallengeKind? _active;
  final Set<String> _completed = {};
  bool _loaded = false;

  void invalidate() {
    _loaded = false;
    _active = null;
    _completed.clear();
    revision.value++;
  }

  BuddyChallengeKind? get activeChallenge => _active;

  int get daysCompletedThisWeek {
    if (_active == null) return 0;
    return _completed.where((k) => k.startsWith('${_active!.name}:')).length;
  }

  double get weekProgress => (daysCompletedThisWeek / 7).clamp(0.0, 1.0);

  bool isDoneToday(BuddyChallengeKind kind) {
    return _completed.contains('${kind.name}:$_todayKey()');
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final kActive = await UserDataScope.scopedKey(_kActive);
    final kDone = await UserDataScope.scopedKey(_kDone);
    final raw = p.getString(kActive);
    if (raw != null) {
      for (final k in BuddyChallengeKind.values) {
        if (k.name == raw) {
          _active = k;
          break;
        }
      }
    }
    final done = p.getString(kDone) ?? '';
    _completed
      ..clear()
      ..addAll(done.split(',').where((e) => e.trim().isNotEmpty));
    _loaded = true;
    revision.value++;
  }

  Future<void> startChallenge(BuddyChallengeKind kind) async {
    await ensureLoaded();
    _active = kind;
    final p = await SharedPreferences.getInstance();
    final kActive = await UserDataScope.scopedKey(_kActive);
    await p.setString(kActive, kind.name);
    revision.value++;
  }

  Future<bool> markTodayComplete({BuddyChallengeKind? kind}) async {
    await ensureLoaded();
    final k = kind ?? _active;
    if (k == null) return false;
    final key = '${k.name}:$_todayKey()';
    if (_completed.contains(key)) return false;
    _completed.add(key);
    final p = await SharedPreferences.getInstance();
    final kDone = await UserDataScope.scopedKey(_kDone);
    await p.setString(kDone, _completed.join(','));
    revision.value++;
    return true;
  }

  /// Auto-complete from health log when thresholds met.
  Future<void> syncFromHealthLog() async {
    await ensureLoaded();
    final active = _active;
    if (active == null) return;
    final log = HealthLogService.instance.logForDate(DateTime.now());
    var met = false;
    switch (active) {
      case BuddyChallengeKind.hydration:
        met = log.waterGlasses >= 6;
      case BuddyChallengeKind.sleep:
        met = log.sleepHours >= 7;
      case BuddyChallengeKind.yoga:
        met = false;
      case null:
        break;
    }
    if (met) await markTodayComplete(kind: active);
  }

  Future<String?> cheerPartner() async {
    final snap = PartnerService.instance.snapshot;
    if (snap?.linked != true) return 'Link a partner on the dashboard to send encouragement.';
    return PartnerService.instance.nudgePartner();
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
