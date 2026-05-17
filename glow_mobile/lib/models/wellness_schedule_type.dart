import 'package:flutter/material.dart';

/// Meal or workout local notification schedules.
enum WellnessScheduleType {
  meal,
  workout;

  String get title => switch (this) {
        meal => 'Meal',
        workout => 'Workout',
      };

  String get screenTitle => switch (this) {
        meal => 'Meal schedule',
        workout => 'Workout schedule',
      };

  String get prefsKey => name;

  int get notifIdBase => switch (this) {
        meal => 93000,
        workout => 94000,
      };

  String get channelId => switch (this) {
        meal => 'glow_meal_reminders',
        workout => 'glow_workout_reminders',
      };

  String get channelTitle => switch (this) {
        meal => 'Meal reminders',
        workout => 'Workout reminders',
      };

  String get channelDescription => switch (this) {
        meal => 'Nudges for breakfast, lunch, dinner, and planned nutrition',
        workout => 'Nudges for yoga, walks, strength, and movement you schedule',
      };

  String get defaultNotificationBody => switch (this) {
        meal => 'Time for your planned meal — nourish your body with intention.',
        workout => 'Scheduled movement — honor what your body needs today.',
      };

  String get emptyHint => switch (this) {
        meal => 'Plan breakfast, lunch, dinner, snacks, or phase-friendly nutrition.',
        workout => 'Schedule yoga, walks, strength, or gentler movement for your cycle.',
      };

  IconData get icon => switch (this) {
        meal => Icons.restaurant_outlined,
        workout => Icons.fitness_center_outlined,
      };

  List<String> get quickAdd => switch (this) {
        meal => [
            'Breakfast',
            'Lunch',
            'Dinner',
            'Snack',
            'Iron-rich meal',
            'Hydration',
            'Prenatal nutrition',
          ],
        workout => [
            'Morning yoga',
            'Walk',
            'Strength',
            'Pilates',
            'Stretch',
            'Light cardio',
            'Restorative',
          ],
      };

  static WellnessScheduleType? fromString(String? raw) {
    return switch (raw) {
      'meal' => WellnessScheduleType.meal,
      'workout' => WellnessScheduleType.workout,
      _ => null,
    };
  }
}
