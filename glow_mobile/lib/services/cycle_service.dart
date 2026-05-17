import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_learning.dart';
import 'user_data_scope.dart';
import '../models/cycle_phase.dart';
import '../models/fertility_intent.dart';

/// Cycle length + period history (device-local). Learns average length after 3+ starts.
class CycleService extends ChangeNotifier {
  CycleService._();
  static final CycleService instance = CycleService._();

  static const _kLastPeriod = 'cycle_last_period_start';
  static const _kPeriodHistory = 'cycle_period_starts_history';
  static const _kCycleLen = 'cycle_typical_length';
  static const _kManualLength = 'cycle_manual_length_override';
  static const _kFertilityIntent = 'cycle_fertility_intent';

  static final RegExp _dateKey = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  DateTime? _lastPeriodStart;
  List<DateTime> _periodStarts = [];
  int _cycleLength = 28;
  bool _manualLengthOverride = false;
  CycleLearningSnapshot _learning = const CycleLearningSnapshot(
    periodStartsLogged: 0,
    validIntervals: [],
    averageCycleLength: null,
    shortestCycle: null,
    longestCycle: null,
    isIrregular: false,
    confidence: CyclePredictionConfidence.none,
  );
  FertilityIntent _fertilityIntent = FertilityIntent.track;
  bool _loaded = false;

  static const int defaultCycleLength = 28;

  static String _toDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime? _parseStoredDate(String raw) {
    final key = _dateKey.firstMatch(raw.trim());
    if (key != null) {
      final y = int.tryParse(key.group(1)!);
      final m = int.tryParse(key.group(2)!);
      final day = int.tryParse(key.group(3)!);
      if (y != null && m != null && day != null) {
        return DateTime(y, m, day);
      }
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  void invalidate() {
    _loaded = false;
    _periodStarts = [];
    _lastPeriodStart = null;
    _cycleLength = defaultCycleLength;
    _manualLengthOverride = false;
    _learning = const CycleLearningSnapshot(
      periodStartsLogged: 0,
      validIntervals: [],
      averageCycleLength: null,
      shortestCycle: null,
      longestCycle: null,
      isIrregular: false,
      confidence: CyclePredictionConfidence.none,
    );
    _fertilityIntent = FertilityIntent.track;
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await reloadFromPrefs();
  }

  Future<void> reloadFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();

    final kHist = await UserDataScope.scopedKey(_kPeriodHistory);
    final kLast = await UserDataScope.scopedKey(_kLastPeriod);
    final kLen = await UserDataScope.scopedKey(_kCycleLen);
    final kManual = await UserDataScope.scopedKey(_kManualLength);
    final kIntent = await UserDataScope.scopedKey(_kFertilityIntent);

    _periodStarts = [];
    final histRaw = p.getString(kHist);
    if (histRaw != null && histRaw.isNotEmpty) {
      try {
        final list = jsonDecode(histRaw);
        if (list is List) {
          for (final e in list) {
            final d = _parseStoredDate(e.toString());
            if (d != null) _periodStarts.add(d);
          }
        }
      } catch (_) {}
    }

    final legacy = p.getString(kLast);
    final legacyDate = legacy != null ? _parseStoredDate(legacy) : null;
    if (legacyDate != null && !_periodStarts.any((d) => _sameDay(d, legacyDate))) {
      _periodStarts.add(legacyDate);
    }

    _periodStarts.sort((a, b) => a.compareTo(b));
    _dedupePeriodStarts();
    _lastPeriodStart = _periodStarts.isEmpty ? null : _periodStarts.last;

    _cycleLength = p.getInt(kLen) ?? defaultCycleLength;
    _manualLengthOverride = p.getBool(kManual) ?? false;
    _fertilityIntent = _parseIntent(p.getString(kIntent));

    _recomputeLearning();
    await _persistHistory();

    _loaded = true;
    notifyListeners();
  }

  void _dedupePeriodStarts() {
    if (_periodStarts.isEmpty) return;
    final out = <DateTime>[];
    for (final d in _periodStarts) {
      if (out.isEmpty || !_sameDay(out.last, d)) {
        out.add(DateTime(d.year, d.month, d.day));
      }
    }
    _periodStarts = out;
    if (_periodStarts.length > CycleLearningRules.maxHistoryEntries) {
      _periodStarts = _periodStarts.sublist(_periodStarts.length - CycleLearningRules.maxHistoryEntries);
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _recomputeLearning() {
    _learning = CycleLearningRules.compute(_periodStarts);
    if (_learning.isPersonalized && !_manualLengthOverride && _learning.averageCycleLength != null) {
      _cycleLength = _learning.averageCycleLength!.clamp(21, 45);
    }
  }

  Future<void> _persistHistory() async {
    final p = await SharedPreferences.getInstance();
    final kHist = await UserDataScope.scopedKey(_kPeriodHistory);
    final kLast = await UserDataScope.scopedKey(_kLastPeriod);
    final kLen = await UserDataScope.scopedKey(_kCycleLen);
    final kManual = await UserDataScope.scopedKey(_kManualLength);
    final kIntent = await UserDataScope.scopedKey(_kFertilityIntent);
    final keys = _periodStarts.map(_toDateKey).toList();
    await p.setString(kHist, jsonEncode(keys));
    if (_lastPeriodStart != null) {
      await p.setString(kLast, _toDateKey(_lastPeriodStart!));
    } else {
      await p.remove(kLast);
    }
    await p.setInt(kLen, _cycleLength);
    await p.setBool(kManual, _manualLengthOverride);
    await p.setString(kIntent, _fertilityIntent.name);
  }

  static FertilityIntent _parseIntent(String? raw) {
    return switch (raw) {
      'ttc' => FertilityIntent.ttc,
      'avoidPregnancy' => FertilityIntent.avoidPregnancy,
      _ => FertilityIntent.track,
    };
  }

  DateTime? get lastPeriodStart => _lastPeriodStart;

  FertilityIntent get fertilityIntent => _fertilityIntent;

  bool get emphasizesFertility =>
      _fertilityIntent == FertilityIntent.ttc ||
      _fertilityIntent == FertilityIntent.avoidPregnancy;

  Future<void> setFertilityIntent(FertilityIntent intent) async {
    await ensureLoaded();
    _fertilityIntent = intent;
    final p = await SharedPreferences.getInstance();
    final kIntent = await UserDataScope.scopedKey(_kFertilityIntent);
    await p.setString(kIntent, intent.name);
    notifyListeners();
  }

  /// All logged period starts, oldest first.
  List<DateTime> get periodStarts => List.unmodifiable(_periodStarts);

  CycleLearningSnapshot get learning => _learning;

  bool get usesPersonalizedPrediction => _learning.isPersonalized && !_manualLengthOverride;

  /// Length used for predictions and phase wheel.
  int get typicalCycleLength => _cycleLength;

  int get effectiveCycleLength => _cycleLength;

  bool get hasCycleAnchor => _lastPeriodStart != null;

  String? get personalizedPredictionCaption {
    if (!usesPersonalizedPrediction) {
      if (_periodStarts.length == 2) {
        return 'Log one more period start to personalize your average cycle length.';
      }
      return null;
    }
    final n = _learning.validIntervals.length;
    final len = _cycleLength;
    return 'Based on your last $n cycle${n == 1 ? '' : 's'} (average $len days).';
  }

  Future<void> setLastPeriodStart(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    if (!_periodStarts.any((x) => _sameDay(x, d))) {
      _periodStarts.add(d);
      _periodStarts.sort((a, b) => a.compareTo(b));
      _dedupePeriodStarts();
    }
    _lastPeriodStart = _periodStarts.last;
    _loaded = true;
    _recomputeLearning();
    await _persistHistory();
    notifyListeners();
  }

  Future<void> clearLastPeriodStart() async {
    _lastPeriodStart = null;
    _periodStarts = [];
    _cycleLength = defaultCycleLength;
    _manualLengthOverride = false;
    _recomputeLearning();
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    final kHist = await UserDataScope.scopedKey(_kPeriodHistory);
    final kLast = await UserDataScope.scopedKey(_kLastPeriod);
    final kLen = await UserDataScope.scopedKey(_kCycleLen);
    final kManual = await UserDataScope.scopedKey(_kManualLength);
    await p.remove(kHist);
    await p.remove(kLast);
    await p.setInt(kLen, defaultCycleLength);
    await p.setBool(kManual, false);
    notifyListeners();
  }

  /// User-chosen typical length; pauses auto-learning until cleared.
  Future<void> setTypicalCycleLength(int len) async {
    _manualLengthOverride = true;
    _cycleLength = len.clamp(21, 45);
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    final kLen = await UserDataScope.scopedKey(_kCycleLen);
    final kManual = await UserDataScope.scopedKey(_kManualLength);
    await p.setInt(kLen, _cycleLength);
    await p.setBool(kManual, true);
    notifyListeners();
  }

  Future<void> useLearnedCycleLength() async {
    _manualLengthOverride = false;
    _recomputeLearning();
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    final kLen = await UserDataScope.scopedKey(_kCycleLen);
    final kManual = await UserDataScope.scopedKey(_kManualLength);
    await p.setBool(kManual, false);
    await p.setInt(kLen, _cycleLength);
    notifyListeners();
  }

  DateTime? get predictedNextPeriodStart {
    if (_lastPeriodStart == null) return null;
    final start = DateTime(_lastPeriodStart!.year, _lastPeriodStart!.month, _lastPeriodStart!.day);
    return start.add(Duration(days: _cycleLength));
  }

  int? get daysUntilNextPeriod {
    final next = predictedNextPeriodStart;
    if (next == null) return null;
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final n0 = DateTime(next.year, next.month, next.day);
    return n0.difference(t0).inDays;
  }

  int get currentDayInCycle {
    final today = DateTime.now();
    return dayInCycleFor(today) ?? 1;
  }

  /// Cycle day (1-based) for [date], or null if no period history covers that day.
  int? dayInCycleFor(DateTime date) {
    if (_periodStarts.isEmpty) return null;
    final d0 = DateTime(date.year, date.month, date.day);
    DateTime? start;
    for (var i = _periodStarts.length - 1; i >= 0; i--) {
      final p = DateTime(
        _periodStarts[i].year,
        _periodStarts[i].month,
        _periodStarts[i].day,
      );
      if (!p.isAfter(d0)) {
        start = p;
        break;
      }
    }
    if (start == null) return null;
    var days = d0.difference(start).inDays + 1;
    if (days < 1) return null;
    while (days > _cycleLength) {
      days -= _cycleLength;
    }
    return days;
  }

  CyclePhase? phaseForDate(DateTime date, {int? cycleLength}) {
    final day = dayInCycleFor(date);
    if (day == null) return null;
    return phaseForDay(day, cycleLength: cycleLength);
  }

  int get demoDayInCycle => currentDayInCycle;
  int get demoCycleLength => _cycleLength;

  CyclePhase phaseForDay(int day, {int? cycleLength}) {
    final len = cycleLength ?? _cycleLength;
    final d = day.clamp(1, len);
    if (d <= 5) return CyclePhase.menstrual;
    if (d <= 13) return CyclePhase.follicular;
    if (d <= 16) return CyclePhase.ovulatory;
    return CyclePhase.luteal;
  }

  static const int approximateLutealLengthDays = 14;

  DateTime? get estimatedOvulationDate {
    final next = predictedNextPeriodStart;
    if (next == null) return null;
    final n = DateTime(next.year, next.month, next.day);
    return n.subtract(const Duration(days: approximateLutealLengthDays));
  }

  (DateTime, DateTime)? get approximateFertileWindow {
    final ov = estimatedOvulationDate;
    if (ov == null) return null;
    final start = ov.subtract(const Duration(days: 5));
    final end = ov.add(const Duration(days: 1));
    return (
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day),
    );
  }

  bool isDateInApproximateFertileWindow(DateTime date) {
    final w = approximateFertileWindow;
    if (w == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final a = DateTime(w.$1.year, w.$1.month, w.$1.day);
    final b = DateTime(w.$2.year, w.$2.month, w.$2.day);
    return d.compareTo(a) >= 0 && d.compareTo(b) <= 0;
  }

  bool isLoggedPeriodStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _periodStarts.any((s) => _sameDay(s, d));
  }

  bool isEstimatedOvulationDay(DateTime date) {
    final ov = estimatedOvulationDate;
    if (ov == null) return false;
    return _sameDay(date, ov);
  }

  int? get daysUntilOvulation {
    final ov = estimatedOvulationDate;
    if (ov == null) return null;
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final o0 = DateTime(ov.year, ov.month, ov.day);
    return o0.difference(t0).inDays;
  }

  bool get isInFertileWindowToday {
    final today = DateTime.now();
    return isDateInApproximateFertileWindow(today);
  }

  /// Days until fertile window starts; negative if already inside; null if unknown.
  int? get daysUntilFertileWindowStart {
    final w = approximateFertileWindow;
    if (w == null) return null;
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final start = DateTime(w.$1.year, w.$1.month, w.$1.day);
    return start.difference(t0).inDays;
  }

  String? get fertilityWindowRangeLabel {
    final w = approximateFertileWindow;
    if (w == null) return null;
    return '${_formatShort(w.$1)} – ${_formatShort(w.$2)}';
  }

  static String _formatShort(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  /// Dashboard / hero headline based on mode + cycle state.
  ({String headline, String? sub}) fertilityDashboardSummary() {
    if (!hasCycleAnchor) {
      return (
        headline: 'Add period',
        sub: 'Log your period start in Calendar to unlock estimates.',
      );
    }

    switch (_fertilityIntent) {
      case FertilityIntent.track:
        final d = daysUntilNextPeriod;
        final next = predictedNextPeriodStart;
        if (next == null) {
          return (headline: 'Add period', sub: null);
        }
        if (d != null && d < 0) {
          return (
            headline: 'Update period',
            sub: 'Your estimate passed — log a new start in the calendar.',
          );
        }
        var sub = 'Next (estimated): ${_formatShort(next)}';
        final cap = personalizedPredictionCaption;
        if (cap != null) sub = '$sub · $cap';
        return (
          headline: d == 0 ? 'Today (estimate)' : d != null ? '$d days' : '—',
          sub: sub,
        );

      case FertilityIntent.ttc:
        if (isInFertileWindowToday) {
          return (
            headline: 'In fertile window',
            sub: fertilityWindowRangeLabel != null
                ? 'Estimated window: ${fertilityWindowRangeLabel!}. Gentle movement, hydration, and rest support TTC.'
                : null,
          );
        }
        final untilOv = daysUntilOvulation;
        if (untilOv != null && untilOv >= 0 && untilOv <= 14) {
          return (
            headline: untilOv == 0 ? 'Ovulation (estimate) today' : 'Ovulation in $untilOv days',
            sub: fertilityWindowRangeLabel != null
                ? 'Estimated fertile window: ${fertilityWindowRangeLabel!}'
                : null,
          );
        }
        final untilFertile = daysUntilFertileWindowStart;
        if (untilFertile != null && untilFertile > 0 && untilFertile <= 21) {
          return (
            headline: 'Fertile window in $untilFertile days',
            sub: fertilityWindowRangeLabel != null
                ? 'Estimated: ${fertilityWindowRangeLabel!}'
                : null,
          );
        }
        return (
          headline: 'TTC mode',
          sub: 'Keep logging period starts — estimates sharpen with more cycles.',
        );

      case FertilityIntent.avoidPregnancy:
        if (isInFertileWindowToday) {
          return (
            headline: 'Higher-fertility days',
            sub: fertilityWindowRangeLabel != null
                ? 'Estimated window: ${fertilityWindowRangeLabel!}. Use reliable contraception — estimates are not birth control.'
                : null,
          );
        }
        final until = daysUntilFertileWindowStart;
        if (until != null && until > 0 && until <= 21) {
          return (
            headline: 'Higher-fertility in $until days',
            sub: fertilityWindowRangeLabel != null
                ? 'Estimated window: ${fertilityWindowRangeLabel!}'
                : null,
          );
        }
        return (
          headline: 'Awareness mode',
          sub: 'Fertile estimates appear on Calendar when your cycle anchor is set.',
        );
    }
  }

  String? modeSpecificPhaseTip(CyclePhase phase) {
    switch (_fertilityIntent) {
      case FertilityIntent.track:
        return null;
      case FertilityIntent.ttc:
        return switch (phase) {
          CyclePhase.menstrual =>
            'TTC tip: rest and replenish iron; many couples pause intense TTC pressure during bleeding.',
          CyclePhase.follicular =>
            'TTC tip: energy often rises — good time for gentle strength and folate-rich meals.',
          CyclePhase.ovulatory =>
            'TTC tip: your estimated fertile window clusters here — stay hydrated and manage stress.',
          CyclePhase.luteal =>
            'TTC tip: implantation may occur — warm meals, sleep, and patience with your body.',
        };
      case FertilityIntent.avoidPregnancy:
        return switch (phase) {
          CyclePhase.menstrual => null,
          CyclePhase.follicular =>
            'Awareness: fertility may rise soon — do not rely on calendar estimates alone.',
          CyclePhase.ovulatory =>
            'Awareness: estimated higher-fertility days — use your chosen contraception consistently.',
          CyclePhase.luteal =>
            'Awareness: fertility typically lowers after ovulation, but estimates can be wrong.',
        };
    }
  }
}
