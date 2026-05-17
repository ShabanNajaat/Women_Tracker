import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether frosted-glass (backdrop blur) effects are enabled.
class GlowEffectsService {
  GlowEffectsService._();
  static final GlowEffectsService instance = GlowEffectsService._();

  static const _key = 'glow_glass_effects_enabled';

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
