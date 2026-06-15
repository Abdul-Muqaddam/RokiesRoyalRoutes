import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/preferences_manager.dart';

// ── Accent color (gold) ──────────────────────────────────────────────────────
final appColorProvider = StateNotifierProvider<AppColorNotifier, Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppColorNotifier(prefs);
});

class AppColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;
  static const _colorKey = 'app_custom_color_v2';
  static const defaultColor = Color(0xFFDC423D); // main brand red

  AppColorNotifier(this._prefs) : super(_loadInitialColor(_prefs));

  static Color _loadInitialColor(SharedPreferences prefs) {
    final hexString = prefs.getString(_colorKey);
    if (hexString != null && hexString.length == 6) {
      return Color(int.parse('FF$hexString', radix: 16));
    }
    return defaultColor;
  }

  Future<void> updateColor(String hexCode) async {
    String finalHex = hexCode;
    if (hexCode.length == 3) {
      finalHex = hexCode.split('').map((c) => '$c$c').join();
    }
    
    if (finalHex.length == 6) {
      final color = Color(int.parse('FF$finalHex', radix: 16));
      await _prefs.setString(_colorKey, finalHex);
      state = color;
    }
  }

  Future<void> resetColor() async {
    await _prefs.remove(_colorKey);
    state = defaultColor;
  }
}

// ── Primary color (navy) ─────────────────────────────────────────────────────
final appPrimaryColorProvider =
    StateNotifierProvider<AppPrimaryColorNotifier, Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppPrimaryColorNotifier(prefs);
});

class AppPrimaryColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;
  static const _colorKey = 'app_custom_primary_color_v2';
  static const defaultColor = Color(0xFF1E1E1E); // dark grey

  AppPrimaryColorNotifier(this._prefs) : super(_loadInitialColor(_prefs));

  static Color _loadInitialColor(SharedPreferences prefs) {
    final hexString = prefs.getString(_colorKey);
    if (hexString != null && hexString.length == 6) {
      return Color(int.parse('FF$hexString', radix: 16));
    }
    return defaultColor;
  }

  Future<void> updateColor(String hexCode) async {
    String finalHex = hexCode;
    if (hexCode.length == 3) {
      finalHex = hexCode.split('').map((c) => '$c$c').join();
    }
    
    if (finalHex.length == 6) {
      final color = Color(int.parse('FF$finalHex', radix: 16));
      await _prefs.setString(_colorKey, finalHex);
      state = color;
    }
  }

  Future<void> resetColor() async {
    await _prefs.remove(_colorKey);
    state = defaultColor;
  }
}
// ── Text color (charcoal) ───────────────────────────────────────────────────
final appTextColorProvider =
    StateNotifierProvider<AppTextColorNotifier, Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppTextColorNotifier(prefs);
});

class AppTextColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;
  static const _colorKey = 'app_custom_text_color_v2';
  static const defaultColor = Color(0xFF333333); // charcoal gray

  AppTextColorNotifier(this._prefs) : super(_loadInitialColor(_prefs));

  static Color _loadInitialColor(SharedPreferences prefs) {
    final hexString = prefs.getString(_colorKey);
    if (hexString != null && hexString.length == 6) {
      return Color(int.parse('FF$hexString', radix: 16));
    }
    return defaultColor;
  }

  Future<void> updateColor(String hexCode) async {
    String finalHex = hexCode;
    if (hexCode.length == 3) {
      finalHex = hexCode.split('').map((c) => '$c$c').join();
    }
    
    if (finalHex.length == 6) {
      final color = Color(int.parse('FF$finalHex', radix: 16));
      await _prefs.setString(_colorKey, finalHex);
      state = color;
    }
  }

  Future<void> resetColor() async {
    await _prefs.remove(_colorKey);
    state = defaultColor;
  }
}
// ── Highlight Text color ────────────────────────────────────────────────────
final appHighlightTextColorProvider =
    StateNotifierProvider<AppHighlightTextColorNotifier, Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppHighlightTextColorNotifier(prefs);
});

class AppHighlightTextColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;
  static const _colorKey = 'app_custom_highlight_text_color_v2';
  static const defaultColor = Color(0xFF1E1E1E); // dark grey

  AppHighlightTextColorNotifier(this._prefs) : super(_loadInitialColor(_prefs));

  static Color _loadInitialColor(SharedPreferences prefs) {
    final hexString = prefs.getString(_colorKey);
    if (hexString != null && hexString.length == 6) {
      return Color(int.parse('FF$hexString', radix: 16));
    }
    return defaultColor;
  }

  Future<void> updateColor(String hexCode) async {
    String finalHex = hexCode;
    if (hexCode.length == 3) {
      finalHex = hexCode.split('').map((c) => '$c$c').join();
    }
    
    if (finalHex.length == 6) {
      final color = Color(int.parse('FF$finalHex', radix: 16));
      await _prefs.setString(_colorKey, finalHex);
      state = color;
    }
  }

  Future<void> resetColor() async {
    await _prefs.remove(_colorKey);
    state = defaultColor;
  }
}
