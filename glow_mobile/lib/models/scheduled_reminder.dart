import 'wellness_schedule_type.dart';

/// A daily local reminder for meals or workouts.
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.type,
    required this.name,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.notificationId,
    this.note,
  });

  final String id;
  final WellnessScheduleType type;
  final String name;
  final int hour;
  final int minute;
  final bool enabled;
  final int notificationId;
  final String? note;

  String get timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  ScheduledReminder copyWith({
    String? name,
    int? hour,
    int? minute,
    bool? enabled,
    String? note,
  }) {
    return ScheduledReminder(
      id: id,
      type: type,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      notificationId: notificationId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        't': type.name,
        'name': name,
        'h': hour,
        'm': minute,
        'e': enabled,
        'n': notificationId,
        'note': note,
      };

  static ScheduledReminder fromJson(Map<String, dynamic> j) {
    final type = WellnessScheduleType.fromString(j['t'] as String?) ?? WellnessScheduleType.meal;
    return ScheduledReminder(
      id: j['id'] as String,
      type: type,
      name: j['name'] as String? ?? type.title,
      hour: (j['h'] as num?)?.toInt() ?? 9,
      minute: (j['m'] as num?)?.toInt() ?? 0,
      enabled: j['e'] as bool? ?? true,
      notificationId: (j['n'] as num?)?.toInt() ?? 0,
      note: j['note'] as String?,
    );
  }
}
