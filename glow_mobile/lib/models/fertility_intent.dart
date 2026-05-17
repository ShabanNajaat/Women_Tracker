/// How Glow frames predictions, calendar highlights, and tips.
enum FertilityIntent {
  /// Period + phase tracking (default).
  track,

  /// Emphasize fertile window & ovulation estimates.
  ttc,

  /// Emphasize higher-fertility days for awareness (not contraception).
  avoidPregnancy,
}

extension FertilityIntentLabels on FertilityIntent {
  String get label => switch (this) {
        FertilityIntent.track => 'Track cycle',
        FertilityIntent.ttc => 'Trying to conceive',
        FertilityIntent.avoidPregnancy => 'Avoid pregnancy',
      };

  String get shortLabel => switch (this) {
        FertilityIntent.track => 'Track',
        FertilityIntent.ttc => 'TTC',
        FertilityIntent.avoidPregnancy => 'Avoid',
      };

  String get settingsDescription => switch (this) {
        FertilityIntent.track =>
          'Balance period estimates with optional fertile-window hints on the calendar.',
        FertilityIntent.ttc =>
          'Highlights your estimated fertile window and ovulation day to support conception planning.',
        FertilityIntent.avoidPregnancy =>
          'Highlights estimated higher-fertility days for awareness. Not a substitute for birth control.',
      };

  String get calendarDisclaimer => switch (this) {
        FertilityIntent.track =>
          'Fertile band is a simple estimate (~14-day luteal model) for planning vibes — not contraception advice.',
        FertilityIntent.ttc =>
          'Estimates only — they do not confirm ovulation or guarantee conception. Talk to your care team for personalized TTC guidance.',
        FertilityIntent.avoidPregnancy =>
          'Estimates are not reliable contraception. Use approved birth control if you want to prevent pregnancy.',
      };
}
