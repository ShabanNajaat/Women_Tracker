import 'package:flutter/material.dart';

/// Supportive micro-challenges (not competitive leaderboards).
enum BuddyChallengeKind {
  hydration,
  sleep,
  yoga;

  String get title => switch (this) {
        hydration => 'Hydration buddy',
        sleep => 'Sleep reset',
        yoga => 'Gentle yoga',
      };

  String get subtitle => switch (this) {
        hydration => '7 days · ~6 glasses of water',
        sleep => '7 days · wind-down & rest',
        yoga => '7 days · 10 min stretch or flow',
      };

  String get encouragement => switch (this) {
        hydration => 'Small sips add up — cheer each other on.',
        sleep => 'Rest is productive. No scores, just showing up.',
        yoga => 'Move gently — consistency over perfection.',
      };

  IconData get icon => switch (this) {
        hydration => Icons.water_drop_outlined,
        sleep => Icons.bedtime_outlined,
        yoga => Icons.self_improvement_outlined,
      };

  String get shareLabel => switch (this) {
        hydration => 'hydration',
        sleep => 'sleep',
        yoga => 'yoga',
      };
}
