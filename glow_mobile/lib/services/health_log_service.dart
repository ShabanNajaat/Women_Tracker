import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_region.dart';
import 'user_data_scope.dart';

/// Daily lifestyle check-ins stored locally (works offline & on web via SharedPreferences).
class DailyHealthLog {
  const DailyHealthLog({
    this.mood = 0,
    this.energy = 0,
    this.pain = 0,
    this.sleepHours = 0,
    this.waterGlasses = 0,
    this.steps = 0,
    this.restingHeartRateBpm = 0,
    this.sleepFromWearable = false,
    this.moodLabel,
    this.symptoms = const [],
    this.bodyPain = const {},
    this.updatedAtMs = 0,
  });

  /// 0 = not set; otherwise 1–5.
  final int mood;
  final int energy;
  final int pain;
  final double sleepHours;
  final int waterGlasses;
  final int steps;
  final int restingHeartRateBpm;
  final bool sleepFromWearable;
  final String? moodLabel;
  final List<String> symptoms;
  /// Region id → intensity 1–3 (mild / moderate / severe).
  final Map<String, int> bodyPain;
  final int updatedAtMs;

  static DailyHealthLog empty() => const DailyHealthLog();

  DailyHealthLog copyWith({
    int? mood,
    int? energy,
    int? pain,
    double? sleepHours,
    int? waterGlasses,
    int? steps,
    int? restingHeartRateBpm,
    bool? sleepFromWearable,
    String? moodLabel,
    List<String>? symptoms,
    Map<String, int>? bodyPain,
    int? updatedAtMs,
  }) {
    return DailyHealthLog(
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      pain: pain ?? this.pain,
      sleepHours: sleepHours ?? this.sleepHours,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      steps: steps ?? this.steps,
      restingHeartRateBpm: restingHeartRateBpm ?? this.restingHeartRateBpm,
      sleepFromWearable: sleepFromWearable ?? this.sleepFromWearable,
      moodLabel: moodLabel ?? this.moodLabel,
      symptoms: symptoms ?? this.symptoms,
      bodyPain: bodyPain ?? this.bodyPain,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'mood': mood,
        'energy': energy,
        'pain': pain,
        'sleep': sleepHours,
        'water': waterGlasses,
        'steps': steps,
        'hr': restingHeartRateBpm,
        'sleepWear': sleepFromWearable,
        'label': moodLabel,
        'sx': symptoms,
        'bp': bodyPain,
        'u': updatedAtMs,
      };

  static DailyHealthLog fromJson(Map<String, dynamic> j) {
    List<String> sx = [];
    final raw = j['sx'];
    if (raw is List) {
      sx = raw.map((e) => e.toString()).toList();
    }
    final bpRaw = j['bp'];
    final bp = <String, int>{};
    if (bpRaw is Map) {
      for (final e in bpRaw.entries) {
        final v = (e.value as num?)?.toInt() ?? 0;
        if (v > 0) bp[e.key.toString()] = v.clamp(1, BodyPainLevel.severe);
      }
    }
    return DailyHealthLog(
      mood: (j['mood'] as num?)?.toInt() ?? 0,
      energy: (j['energy'] as num?)?.toInt() ?? 0,
      pain: (j['pain'] as num?)?.toInt() ?? 0,
      sleepHours: (j['sleep'] as num?)?.toDouble() ?? 0,
      waterGlasses: (j['water'] as num?)?.toInt() ?? 0,
      steps: (j['steps'] as num?)?.toInt() ?? 0,
      restingHeartRateBpm: (j['hr'] as num?)?.toInt() ?? 0,
      sleepFromWearable: j['sleepWear'] == true,
      moodLabel: j['label'] as String?,
      symptoms: sx,
      bodyPain: bp,
      updatedAtMs: (j['u'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Aggregated body-zone stats for trend cards.
class BodyPainHotspot {
  const BodyPainHotspot({
    required this.regionId,
    required this.dayCount,
    required this.avgLevel,
  });

  final String regionId;
  final int dayCount;
  final double avgLevel;
}

class HealthLogService extends ChangeNotifier {
  HealthLogService._();
  static final HealthLogService instance = HealthLogService._();

  static const _kBlob = 'glow_health_logs_v1';

  final Map<String, DailyHealthLog> _logs = {};
  bool _loaded = false;

  void invalidate() {
    _loaded = false;
    _logs.clear();
    notifyListeners();
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final kBlob = await UserDataScope.scopedKey(_kBlob);
    final raw = p.getString(kBlob);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in decoded.entries) {
          final v = e.value;
          if (v is Map<String, dynamic>) {
            _logs[e.key] = DailyHealthLog.fromJson(v);
          }
        }
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    final kBlob = await UserDataScope.scopedKey(_kBlob);
    final out = <String, dynamic>{};
    for (final e in _logs.entries) {
      out[e.key] = e.value.toJson();
    }
    await p.setString(kBlob, jsonEncode(out));
    notifyListeners();
  }

  DailyHealthLog? logFor(String key) => _logs[key];

  DailyHealthLog logForDate(DateTime d) => _logs[dateKey(d)] ?? DailyHealthLog.empty();

  /// Last [days] calendar days ending at [end] (inclusive), oldest first.
  List<(String key, DailyHealthLog log)> rangeEnding(DateTime end, int days) {
    final list = <(String, DailyHealthLog)>[];
    for (var i = days - 1; i >= 0; i--) {
      final dt = DateTime(end.year, end.month, end.day).subtract(Duration(days: i));
      final k = dateKey(dt);
      list.add((k, _logs[k] ?? DailyHealthLog.empty()));
    }
    return list;
  }

  static int moodScoreFromLabel(String label) {
    switch (label) {
      case 'Calm':
        return 4;
      case 'Energized':
      case 'Hopeful':
        return 5;
      case 'Low':
      case 'Irritable':
      case 'Drained':
        return 2;
      default:
        return 3;
    }
  }

  /// Called from mood board — always local, even when cloud save fails.
  Future<void> mergeMoodFromLabel(String label) async {
    await ensureLoaded();
    final k = dateKey(DateTime.now());
    final existing = _logs[k] ?? DailyHealthLog.empty();
    _logs[k] = existing.copyWith(
      mood: moodScoreFromLabel(label),
      moodLabel: label,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  Future<void> saveToday({
    required int mood,
    required int energy,
    required int pain,
    required double sleepHours,
    required int waterGlasses,
    List<String>? symptoms,
  }) async {
    await ensureLoaded();
    final k = dateKey(DateTime.now());
    final existing = _logs[k] ?? DailyHealthLog.empty();
    _logs[k] = existing.copyWith(
      mood: mood.clamp(1, 5),
      energy: energy.clamp(1, 5),
      pain: pain.clamp(1, 5),
      sleepHours: sleepHours.clamp(0, 14),
      waterGlasses: waterGlasses.clamp(0, 20),
      symptoms: symptoms ?? existing.symptoms,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  Future<void> toggleSymptomToday(String symptom) async {
    await ensureLoaded();
    final k = dateKey(DateTime.now());
    final existing = _logs[k] ?? DailyHealthLog.empty();
    final sx = List<String>.from(existing.symptoms);
    if (sx.contains(symptom)) {
      sx.remove(symptom);
    } else {
      if (sx.length < 16) sx.add(symptom);
    }
    _logs[k] = existing.copyWith(
      symptoms: sx,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  /// Merges wearable rows without overwriting manual mood/energy check-ins.
  Future<void> mergeWearableForDay(
    String dateKey, {
    int? steps,
    double? sleepHours,
    int? restingHeartRateBpm,
  }) async {
    await ensureLoaded();
    final existing = _logs[dateKey] ?? DailyHealthLog.empty();
    final useSleep = sleepHours != null &&
        (existing.sleepHours <= 0 || existing.sleepFromWearable);
    _logs[dateKey] = existing.copyWith(
      steps: steps != null && steps > 0 ? steps : existing.steps,
      sleepHours: useSleep ? sleepHours.clamp(0.0, 24.0) : existing.sleepHours,
      sleepFromWearable: useSleep ? true : existing.sleepFromWearable,
      restingHeartRateBpm: restingHeartRateBpm != null && restingHeartRateBpm > 0
          ? restingHeartRateBpm
          : existing.restingHeartRateBpm,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  Map<String, int> bodyPainForDate(DateTime d) =>
      Map<String, int>.from(logForDate(d).bodyPain);

  int bodyPainZoneCountForDate(DateTime d) =>
      logForDate(d).bodyPain.values.where((v) => v > 0).length;

  Future<void> cycleBodyRegionToday(String regionId) async {
    if (BodyRegions.byId(regionId) == null) return;
    await ensureLoaded();
    final k = dateKey(DateTime.now());
    final existing = _logs[k] ?? DailyHealthLog.empty();
    final bp = Map<String, int>.from(existing.bodyPain);
    final next = BodyPainLevel.cycle(bp[regionId] ?? 0);
    if (next <= 0) {
      bp.remove(regionId);
    } else {
      bp[regionId] = next;
    }
    _logs[k] = existing.copyWith(
      bodyPain: bp,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  Future<void> clearBodyRegionToday(String regionId) async {
    await ensureLoaded();
    final k = dateKey(DateTime.now());
    final existing = _logs[k] ?? DailyHealthLog.empty();
    final bp = Map<String, int>.from(existing.bodyPain)..remove(regionId);
    _logs[k] = existing.copyWith(
      bodyPain: bp,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  Future<void> clearBodyPainToday() async {
    await ensureLoaded();
    final k = dateKey(DateTime.now());
    final existing = _logs[k] ?? DailyHealthLog.empty();
    _logs[k] = existing.copyWith(
      bodyPain: const {},
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  /// Regions logged on the most days in the last [days] (min 2 days to qualify).
  List<BodyPainHotspot> bodyPainHotspotsLastDays(int days) {
    final totals = <String, List<int>>{};
    for (final (_, log) in rangeEnding(DateTime.now(), days)) {
      for (final e in log.bodyPain.entries) {
        if (e.value <= 0) continue;
        totals.putIfAbsent(e.key, () => []).add(e.value);
      }
    }
    final out = <BodyPainHotspot>[];
    for (final e in totals.entries) {
      if (e.value.length < 2) continue;
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      out.add(BodyPainHotspot(regionId: e.key, dayCount: e.value.length, avgLevel: avg));
    }
    out.sort((a, b) {
      final byDays = b.dayCount.compareTo(a.dayCount);
      if (byDays != 0) return byDays;
      return b.avgLevel.compareTo(a.avgLevel);
    });
    return out;
  }

  Future<void> addCustomSymptom(String raw) async {
    final t = raw.trim();
    if (t.isEmpty) return;
    await ensureLoaded();
    final k = dateKey(DateTime.now());
    final existing = _logs[k] ?? DailyHealthLog.empty();
    final sx = List<String>.from(existing.symptoms);
    final label = t.length > 32 ? '${t.substring(0, 32)}…' : t;
    if (!sx.contains(label) && sx.length < 16) sx.add(label);
    _logs[k] = existing.copyWith(
      symptoms: sx,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  /// Composite 0–100 from the last [days] days (education / motivation — not medical advice).
  int? weeklyGlowScore({int days = 7}) {
    final series = rangeEnding(DateTime.now(), days);
    double moodSum = 0, energySum = 0, painSum = 0;
    int moodN = 0, energyN = 0, painN = 0;
    double sleepSum = 0;
    int sleepN = 0;
    double waterSum = 0;
    int waterN = 0;
    double stepsSum = 0;
    int stepsN = 0;
    for (final (_, log) in series) {
      if (log.mood > 0) {
        moodSum += log.mood;
        moodN++;
      }
      if (log.energy > 0) {
        energySum += log.energy;
        energyN++;
      }
      if (log.pain > 0) {
        painSum += log.pain;
        painN++;
      }
      if (log.sleepHours > 0) {
        sleepSum += log.sleepHours;
        sleepN++;
      }
      if (log.waterGlasses > 0) {
        waterSum += log.waterGlasses;
        waterN++;
      }
      if (log.steps > 0) {
        stepsSum += log.steps;
        stepsN++;
      }
    }
    if (moodN == 0 && energyN == 0 && stepsN == 0) return null;
    final moodPart = moodN > 0 ? (moodSum / moodN / 5) * 34 : 0.0;
    final energyPart = energyN > 0 ? (energySum / energyN / 5) * 34 : 0.0;
    final painPart = painN > 0 ? ((5 - (painSum / painN)) / 5) * 12 : 12.0;
    final sleepPart = sleepN > 0 ? (sleepSum / sleepN / 8).clamp(0.0, 1.0) * 6 : 0.0;
    final waterPart = waterN > 0 ? (waterSum / waterN / 8).clamp(0.0, 1.0) * 4 : 0.0;
    final stepsPart =
        stepsN > 0 ? (stepsSum / stepsN / 10000).clamp(0.0, 1.0) * 6 : 0.0;
    final total =
        (moodPart + energyPart + painPart + sleepPart + waterPart + stepsPart).round().clamp(0, 100);
    return total;
  }
}
