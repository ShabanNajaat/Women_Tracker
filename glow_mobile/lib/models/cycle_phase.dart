/// Represents the different phases of the menstrual cycle.
enum CyclePhase {
  menstrual,
  follicular,
  ovulatory,
  luteal;

  /// Returns a human-readable name for the phase.
  String get displayName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulatory:
        return 'Ovulatory';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  /// Returns a description of the phase.
  String get description {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Progesterone drops and the lining sheds — cramps often come from prostaglandins. Prioritize rest, warmth, and iron-friendly foods.';
      case CyclePhase.follicular:
        return 'Estrogen climbs after your period, which for many people means clearer focus and gentler mood. A good time to build strength or start new routines.';
      case CyclePhase.ovulatory:
        return 'A surge in LH triggers ovulation; you may feel more social or energetic. Stay hydrated if you’re training hard.';
      case CyclePhase.luteal:
        return 'Progesterone rises after ovulation; some people feel bloating, cravings, or PMS as the period approaches. Magnesium-rich foods and lighter workouts can help.';
    }
  }
}
