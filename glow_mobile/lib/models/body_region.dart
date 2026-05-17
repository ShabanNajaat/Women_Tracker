import 'dart:ui';

/// Anatomical zones for the interactive body pain map (wellness logging only).
class BodyRegionDef {
  const BodyRegionDef({
    required this.id,
    required this.label,
    required this.onFront,
    required this.onBack,
    required this.rect,
  });

  final String id;
  final String label;
  /// Normalized rect within the silhouette (0–1), origin top-left.
  final Rect rect;
  final bool onFront;
  final bool onBack;

  bool visibleOnFrontView(bool backView) => backView ? onBack : onFront;
}

/// Pain intensity for a body zone: 1 mild → 3 severe.
abstract final class BodyPainLevel {
  static const int mild = 1;
  static const int moderate = 2;
  static const int severe = 3;

  static int cycle(int current) {
    if (current <= 0) return mild;
    if (current >= severe) return 0;
    return current + 1;
  }

  static String label(int level) {
    return switch (level) {
      mild => 'Mild',
      moderate => 'Moderate',
      severe => 'Severe',
      _ => 'None',
    };
  }
}

abstract final class BodyRegions {
  static const all = <BodyRegionDef>[
    BodyRegionDef(
      id: 'head',
      label: 'Head',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.38, 0.02, 0.24, 0.09),
    ),
    BodyRegionDef(
      id: 'neck',
      label: 'Neck',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.42, 0.10, 0.16, 0.05),
    ),
    BodyRegionDef(
      id: 'chest',
      label: 'Chest',
      onFront: true,
      onBack: false,
      rect: Rect.fromLTWH(0.32, 0.15, 0.36, 0.11),
    ),
    BodyRegionDef(
      id: 'upper_back',
      label: 'Upper back',
      onFront: false,
      onBack: true,
      rect: Rect.fromLTWH(0.30, 0.15, 0.40, 0.12),
    ),
    BodyRegionDef(
      id: 'abdomen',
      label: 'Abdomen',
      onFront: true,
      onBack: false,
      rect: Rect.fromLTWH(0.34, 0.26, 0.32, 0.12),
    ),
    BodyRegionDef(
      id: 'lower_back',
      label: 'Lower back',
      onFront: false,
      onBack: true,
      rect: Rect.fromLTWH(0.34, 0.27, 0.32, 0.11),
    ),
    BodyRegionDef(
      id: 'pelvis',
      label: 'Pelvis / uterus',
      onFront: true,
      onBack: false,
      rect: Rect.fromLTWH(0.36, 0.38, 0.28, 0.09),
    ),
    BodyRegionDef(
      id: 'glutes',
      label: 'Glutes / hips',
      onFront: false,
      onBack: true,
      rect: Rect.fromLTWH(0.34, 0.38, 0.32, 0.10),
    ),
    BodyRegionDef(
      id: 'l_shoulder',
      label: 'Left shoulder',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.18, 0.14, 0.14, 0.08),
    ),
    BodyRegionDef(
      id: 'r_shoulder',
      label: 'Right shoulder',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.68, 0.14, 0.14, 0.08),
    ),
    BodyRegionDef(
      id: 'l_arm',
      label: 'Left arm',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.10, 0.22, 0.12, 0.18),
    ),
    BodyRegionDef(
      id: 'r_arm',
      label: 'Right arm',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.78, 0.22, 0.12, 0.18),
    ),
    BodyRegionDef(
      id: 'l_leg',
      label: 'Left leg',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.30, 0.48, 0.16, 0.38),
    ),
    BodyRegionDef(
      id: 'r_leg',
      label: 'Right leg',
      onFront: true,
      onBack: true,
      rect: Rect.fromLTWH(0.54, 0.48, 0.16, 0.38),
    ),
  ];

  static BodyRegionDef? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static Iterable<BodyRegionDef> forView(bool backView) =>
      all.where((r) => r.visibleOnFrontView(backView));
}
