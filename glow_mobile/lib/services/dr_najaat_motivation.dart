import 'dart:math';

/// Curated motivational lines for the dashboard hero (rotates on each build / visit).
class DrNajaatMotivation {
  DrNajaatMotivation._();

  static const List<String> _lines = [
    "Dr. Najaat: You're allowed to move gently today — progress isn't a race.",
    'Dr. Najaat: Your body is doing a lot behind the scenes. A little kindness toward yourself counts.',
    'Dr. Najaat: Rest is not laziness. It is part of how you heal and reset.',
    'Dr. Najaat: Small steps still change the week. What is one tiny thing that would feel good?',
    'Dr. Najaat: However you woke up today, you still deserve care — water, food, and a softer voice in your head.',
    'Dr. Najaat: Stress and hormones can tangle together. You are not "too much" for noticing that.',
    'Dr. Najaat: Hydration and a slow breath are underrated medicine on busy days.',
    'Dr. Najaat: You do not have to earn rest or joy. They are part of being human.',
    'Dr. Najaat: If today is heavy, narrow your world to the next kind choice — one is enough.',
    'Dr. Najaat: Tracking your cycle is a way of listening, not judging. I am glad you are here.',
    'Dr. Najaat: Strength sometimes looks like asking for help. That takes courage.',
    'Dr. Najaat: Your feelings around your health are real, even when tests look "fine."',
    'Dr. Najaat: Celebration can be quiet: you showed up for yourself again.',
    'Dr. Najaat: Boundaries protect your energy. It is okay to protect peace.',
    'Dr. Najaat: One nourishing meal, one stretch, one honest check-in — that is enough for a win.',
    'Dr. Najaat: You are not behind. You are moving through a season that asks different things of you.',
    'Dr. Najaat: Curiosity beats criticism. What would it feel like to get curious about your body today?',
    'Dr. Najaat: Light matters, sleep matters, connection matters — you are worth those basics.',
    'Dr. Najaat: If comparison crept in, come back to your own path. It was never a contest.',
    'Dr. Najaat: I am cheering for you — not for perfection, for persistence and gentleness.',
  ];

  /// New line each time the dashboard hero is built (e.g. every time you open Home).
  static String randomLine() {
    final i = Random().nextInt(_lines.length);
    return _lines[i];
  }
}
