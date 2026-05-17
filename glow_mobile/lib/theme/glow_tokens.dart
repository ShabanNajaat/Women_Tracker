import 'package:flutter/material.dart';

/// Soft Premium Minimalism — canonical hex palette (aligned with web CSS).
abstract final class GlowTokens {
  /// Rose-pink accent — light mode primary feel (“girlish” without neon).
  static const Color rose = Color(0xFFDA6B9A);

  /// Main lavender — primary actions, highlights (works on dark).
  static const Color lavender = Color(0xFFB8A2D6);

  /// Soft sage — supporting tones (light).
  static const Color sage = Color(0xFFE2E8D5);

  /// Blush sage — encouragement / secondary on pink-light theme.
  static const Color blushSage = Color(0xFFDCE8D0);

  /// Near-black background (login / legacy); same base as Settings sidebar in dark.
  static const Color midnight = Color(0xFF0D0D0D);

  /// Light scaffold — soft pink-white (readable, not grey).
  static const Color creamSurface = Color(0xFFFFF8FB);

  /// Deep purple (legacy accents / Glow Space gradients).
  static const Color darkPurpleBase = Color(0xFF0C0610);

  /// Settings-style dark scaffold (main app dark mode).
  static const Color darkNeutralBase = Color(0xFF0D0D0D);

  /// Settings-style secondary panel (detail pane, bottom nav).
  static const Color darkNeutralPane = Color(0xFF161616);

  /// Opaque cards on neutral dark (no milky glass).
  static const Color darkNeutralCard = Color(0xFF1C1C1E);

  /// Elevated card purple on dark backgrounds (solid).
  static const Color darkLavenderCard = Color(0xFF2A1F3D);
  
  /// Surface glass background.
  static const Color surface = Color(0xFF2A2A2E);

  /// Navigation rail — muted grey panel.
  static const Color railBackground = Color(0xFF3A3A42);

  /// Inactive labels/icons on [railBackground] (~high contrast).
  static const Color railInactive = Color(0xFFE8E0F5);

  /// Selected / active nav accent on rail.
  static const Color railActive = lavender;

  /// Deep plum for secondary emphasis (headings, strong inactive on light tints).
  static const Color deepPlum = Color(0xFF4A3040);

  /// Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE895B5), Color(0xFFCE6B9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Login / splash dark backdrop — true black with a soft pink wash (not violet).
  static const Gradient darkLoginBackdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D0D0D),
      Color(0xFF121010),
      Color(0xFF161214),
      Color(0xFF0D0D0D),
    ],
    stops: [0.0, 0.4, 0.75, 1.0],
  );
}
