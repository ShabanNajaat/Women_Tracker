import 'package:flutter/material.dart';

import 'cycle_phase.dart';

/// Community discussion space keyed to a cycle phase.
class PhaseRoomInfo {
  const PhaseRoomInfo({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.apiValue,
  });

  final CyclePhase phase;
  final String title;
  final String subtitle;
  final IconData icon;
  final String apiValue;

  static const all = <PhaseRoomInfo>[
    PhaseRoomInfo(
      phase: CyclePhase.menstrual,
      title: 'Rest & restore',
      subtitle: 'Cramps, fatigue, comfort — support without medical advice.',
      icon: Icons.self_improvement_outlined,
      apiValue: 'menstrual',
    ),
    PhaseRoomInfo(
      phase: CyclePhase.follicular,
      title: 'Rising energy',
      subtitle: 'New habits, focus, and building strength together.',
      icon: Icons.wb_sunny_outlined,
      apiValue: 'follicular',
    ),
    PhaseRoomInfo(
      phase: CyclePhase.ovulatory,
      title: 'Peak vitality',
      subtitle: 'Social energy, movement wins, and celebration.',
      icon: Icons.bolt_outlined,
      apiValue: 'ovulatory',
    ),
    PhaseRoomInfo(
      phase: CyclePhase.luteal,
      title: 'Gentle support',
      subtitle: 'PMS, cravings, mood shifts — you are not alone.',
      icon: Icons.favorite_outline,
      apiValue: 'luteal',
    ),
  ];

  static PhaseRoomInfo? forPhase(CyclePhase phase) {
    for (final r in all) {
      if (r.phase == phase) return r;
    }
    return null;
  }

  static PhaseRoomInfo? fromApiValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final r in all) {
      if (r.apiValue == raw) return r;
    }
    return null;
  }
}
