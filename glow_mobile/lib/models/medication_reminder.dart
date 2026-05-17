/// A local daily reminder for medication or supplements.
class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.notificationId,
    this.note,
  });

  final String id;
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

  MedicationReminder copyWith({
    String? name,
    int? hour,
    int? minute,
    bool? enabled,
    String? note,
  }) {
    return MedicationReminder(
      id: id,
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
        'name': name,
        'h': hour,
        'm': minute,
        'e': enabled,
        'n': notificationId,
        'note': note,
      };

  static MedicationReminder fromJson(Map<String, dynamic> j) {
    return MedicationReminder(
      id: j['id'] as String,
      name: j['name'] as String? ?? 'Medication',
      hour: (j['h'] as num?)?.toInt() ?? 9,
      minute: (j['m'] as num?)?.toInt() ?? 0,
      enabled: j['e'] as bool? ?? true,
      notificationId: (j['n'] as num?)?.toInt() ?? 0,
      note: j['note'] as String?,
    );
  }
}
