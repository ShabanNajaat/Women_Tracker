import 'package:flutter/material.dart';
import 'glow_tokens.dart';

/// Material 3 themes — light: elegant pink; dark: Settings-style true black + lavender glow accents.
abstract final class GlowAppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: GlowTokens.rose,
      brightness: Brightness.light,
    ).copyWith(
      surface: GlowTokens.creamSurface,
      onSurface: GlowTokens.deepPlum,
      onSurfaceVariant: const Color(0xFF855C72),
      surfaceContainerLow: const Color(0xFFFFF0F5),
      surfaceContainer: const Color(0xFFFFE8F0),
      surfaceContainerHigh: const Color(0xFFFFDCE8),
      surfaceContainerHighest: const Color(0xFFFFFBFD),
      primary: const Color(0xFFD94F8C),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFD0E4),
      onPrimaryContainer: const Color(0xFF5B1038),
      secondary: GlowTokens.blushSage,
      onSecondary: GlowTokens.deepPlum,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static ThemeData dark() {
    // Same neutrals as Settings (0x0D / 0x16 / card). Lavender = glow accents.
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: GlowTokens.lavender,
      onPrimary: Color(0xFF141018),
      primaryContainer: Color(0xFF3D2F55),
      onPrimaryContainer: Color(0xFFE8DDF5),
      secondary: Color(0xFFC5D4B8),
      onSecondary: Color(0xFF141418),
      tertiary: GlowTokens.rose,
      onTertiary: Colors.white,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: GlowTokens.darkNeutralBase,
      onSurface: Color(0xFFF2F2F7),
      onSurfaceVariant: Color(0xFF9B9BA8),
      outline: Color(0xFF3C3C40),
      outlineVariant: Color(0xFF2C2C30),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE8E0F0),
      onInverseSurface: Color(0xFF1E1428),
      inversePrimary: Color(0xFF6B5089),
      surfaceTint: GlowTokens.lavender,
      surfaceContainerHighest: GlowTokens.darkNeutralCard,
      surfaceContainerHigh: GlowTokens.darkNeutralPane,
      surfaceContainer: Color(0xFF141414),
      surfaceContainerLow: Color(0xFF101010),
      surfaceDim: GlowTokens.darkNeutralBase,
      surfaceBright: Color(0xFF242428),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
