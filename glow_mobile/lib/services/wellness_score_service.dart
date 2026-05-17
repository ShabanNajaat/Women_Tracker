import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_data_scope.dart';

/// Glow points earned from check-ins, journal saves, and mini wellness quizzes.
class WellnessScoreService {
  WellnessScoreService._();
  static final WellnessScoreService instance = WellnessScoreService._();

  static const _kPoints = 'wellness_glow_points';
  static const _kLastJournalBonus = 'wellness_last_journal_bonus_date';
  static const _kLastQuizBonus = 'wellness_last_quiz_bonus_date';
  static const _kLastCheckIn = 'wellness_last_check_in_date';

  int _points = 0;
  bool _loaded = false;

  /// UI listens for live score updates after check-ins / journal / quiz.
  static final ValueNotifier<int> pointsListenable = ValueNotifier<int>(0);

  int get points => _points;

  void invalidate() {
    _loaded = false;
    _points = 0;
    pointsListenable.value = 0;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final kPoints = await UserDataScope.scopedKey(_kPoints);
    _points = p.getInt(kPoints) ?? 0;
    _loaded = true;
    pointsListenable.value = _points;
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    final kPoints = await UserDataScope.scopedKey(_kPoints);
    await p.setInt(kPoints, _points);
    pointsListenable.value = _points;
  }

  /// One small mood check-in on home (MoodBoard) — +5 max once per local day.
  Future<void> maybeAwardDailyCheckIn() async {
    await ensureLoaded();
    final p = await SharedPreferences.getInstance();
    final today = _todayKey();
    final kCheckIn = await UserDataScope.scopedKey(_kLastCheckIn);
    if (p.getString(kCheckIn) == today) return;
    await p.setString(kCheckIn, today);
    _points += 5;
    await _persist();
  }

  /// Journal save — +15 max once per day.
  Future<void> maybeAwardJournalBonus() async {
    await ensureLoaded();
    final p = await SharedPreferences.getInstance();
    final today = _todayKey();
    final kJournal = await UserDataScope.scopedKey(_kLastJournalBonus);
    if (p.getString(kJournal) == today) return;
    await p.setString(kJournal, today);
    _points += 15;
    await _persist();
  }

  /// Mini quiz on dashboard — +25 when answered correctly, once per day.
  Future<bool> tryAwardQuizBonus() async {
    await ensureLoaded();
    final p = await SharedPreferences.getInstance();
    final today = _todayKey();
    final kQuiz = await UserDataScope.scopedKey(_kLastQuizBonus);
    if (p.getString(kQuiz) == today) return false;
    await p.setString(kQuiz, today);
    _points += 25;
    await _persist();
    return true;
  }

  /// 30-day challenge — +15 Glow points the first time you complete any daily wellness action (mood / journal / quiz).
  Future<void> awardChallengeDay() async {
    await ensureLoaded();
    final p = await SharedPreferences.getInstance();
    final today = _todayKey();
    final kChallenge = await UserDataScope.scopedKey('challenge_pts_$today');
    if (p.getBool(kChallenge) == true) return;
    await p.setBool(kChallenge, true);
    _points += 15;
    await _persist();
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
