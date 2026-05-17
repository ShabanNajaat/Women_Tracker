import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'partner_service.dart';
import 'user_data_scope.dart';
import 'wellness_score_service.dart';

/// 30-day wellness challenge: one check-in per calendar day counts toward the streak.
class ChallengeService {
  ChallengeService._();
  static final ChallengeService instance = ChallengeService._();

  static const totalDays = 30;
  static const _kStart = 'glow_challenge_start_iso';
  static const _kDone = 'glow_challenge_completed_dates'; // comma-separated yyyy-MM-dd

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  DateTime? _start;
  final Set<String> _completed = {};
  bool _loaded = false;

  void invalidate() {
    _loaded = false;
    _start = null;
    _completed.clear();
    revision.value = revision.value + 1;
  }

  DateTime? get startDate => _start;
  int get completedCount => daysCompletedInChallenge;

  /// Days marked complete within the current 30-day window from [_start].
  int get daysCompletedInChallenge {
    if (_start == null) return 0;
    final s = DateTime(_start!.year, _start!.month, _start!.day);
    var count = 0;
    for (final k in _completed) {
      final parts = k.split('-');
      if (parts.length != 3) continue;
      try {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final diff = d.difference(s).inDays;
        if (diff >= 0 && diff < totalDays) count++;
      } catch (_) {}
    }
    return count;
  }

  double get progress01 => (daysCompletedInChallenge / totalDays).clamp(0.0, 1.0);

  /// Consecutive calendar days with a check-in (today or ending yesterday).
  int get currentDailyStreak {
    if (_completed.isEmpty) return 0;
    final today = DateTime.now();
    var d = DateTime(today.year, today.month, today.day);
    final todayKey = _todayKey();
    if (!_completed.contains(todayKey)) {
      d = d.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (true) {
      final k =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (!_completed.contains(k)) break;
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool get checkedInToday => _completed.contains(_todayKey());

  /// Calendar day index 1–30 from challenge start (capped).
  int get currentDayNumber {
    if (_start == null) return 1;
    final s = DateTime(_start!.year, _start!.month, _start!.day);
    final t = DateTime.now();
    final t0 = DateTime(t.year, t.month, t.day);
    final n = t0.difference(s).inDays + 1;
    return n.clamp(1, totalDays);
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final kStart = await UserDataScope.scopedKey(_kStart);
    final kDone = await UserDataScope.scopedKey(_kDone);
    final startIso = p.getString(kStart);
    if (startIso != null) {
      _start = DateTime.tryParse(startIso);
    }
    if (_start == null) {
      final now = DateTime.now();
      _start = DateTime(now.year, now.month, now.day);
      await p.setString(kStart, _start!.toIso8601String());
    }
    final raw = p.getString(kDone) ?? '';
    _completed.clear();
    for (final part in raw.split(',')) {
      final k = part.trim();
      if (k.isNotEmpty) _completed.add(k);
    }
    _loaded = true;
    revision.value = revision.value + 1;
  }

  Future<void> _persistDone() async {
    final p = await SharedPreferences.getInstance();
    final kDone = await UserDataScope.scopedKey(_kDone);
    await p.setString(kDone, _completed.join(','));
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Call after mood save, journal save, or quiz success — at most once per day for challenge + bonus points.
  Future<void> recordTodayProgressIfNeeded() async {
    await ensureLoaded();
    final key = _todayKey();
    if (_completed.contains(key)) return;
    _completed.add(key);
    await _persistDone();
    await WellnessScoreService.instance.awardChallengeDay();
    revision.value = revision.value + 1;
    await PartnerService.instance.syncTodayCheckIn();
  }

  /// Restart challenge (optional, e.g. settings later).
  Future<void> resetChallenge() async {
    final p = await SharedPreferences.getInstance();
    final kStart = await UserDataScope.scopedKey(_kStart);
    final kDone = await UserDataScope.scopedKey(_kDone);
    await p.remove(kDone);
    _completed.clear();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day);
    await p.setString(kStart, _start!.toIso8601String());
    revision.value = revision.value + 1;
  }

  String buildPartnerStreakMessage({String? partnerName}) {
    final streak = currentDailyStreak;
    final day = currentDayNumber;
    final who = partnerName != null && partnerName.isNotEmpty ? partnerName : 'partner';
    return 'Day $day of my Glow challenge — $streak-day streak 🔥 '
        'I checked in today! Rooting for you, $who.';
  }
}
