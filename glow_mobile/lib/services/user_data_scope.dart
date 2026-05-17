import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'buddy_challenge_service.dart';
import 'challenge_service.dart';
import 'cycle_service.dart';
import 'health_log_service.dart';
import 'medication_reminder_service.dart';
import 'wellness_schedule_service.dart';
import 'wellness_score_service.dart';

/// Per-account storage keys and cache resets when the signed-in user changes.
abstract final class UserDataScope {
  static final ValueNotifier<int> sessionEpoch = ValueNotifier<int>(0);

  /// Prefix SharedPreferences keys with the active user id (or guest scope).
  static Future<String> scopedKey(String baseKey) async {
    final scope = await ApiService().userScope();
    return 'glow_${scope}_$baseKey';
  }

  /// Clears in-memory caches so the next load reads only the new user's data.
  static Future<void> notifySessionChanged() async {
    CycleService.instance.invalidate();
    HealthLogService.instance.invalidate();
    WellnessScoreService.instance.invalidate();
    ChallengeService.instance.invalidate();
    BuddyChallengeService.instance.invalidate();
    MedicationReminderService.instance.invalidate();
    WellnessScheduleService.instance.invalidate();
    sessionEpoch.value++;
  }
}
