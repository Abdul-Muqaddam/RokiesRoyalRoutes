import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import '../models/home_settings.dart';
import '../models/profile_settings.dart';
import '../models/booking_settings.dart';
import '../remote/api_service.dart';
import '../repositories/auth_repository_impl.dart';
import 'app_color_provider.dart';

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier(ref);
});

class AppConfigNotifier extends StateNotifier<AppConfig> {
  final Ref _ref;
  AppConfigNotifier(this._ref) : super(AppConfig.defaultConfig());

  Future<void> fetchConfig() async {
    try {
      final config = await _ref.read(apiServiceProvider).getAppConfig();
      state = config;
      await _syncToLocalProviders(config);
    } catch (e) {
      debugPrint('Error fetching app config: $e');
    }
  }

  Future<void> updateConfig(AppConfig config) async {
    try {
      await _ref.read(apiServiceProvider).updateAppConfig(config);
      // Re-fetch to ensure we have the absolute latest from the server
      await fetchConfig();
    } catch (e) {
      debugPrint('Error updating app config: $e');
      rethrow;
    }
  }

  Future<void> _syncToLocalProviders(AppConfig config) async {
    // Colors
    await _ref.read(appColorProvider.notifier).updateColor(config.accentColor);
    await _ref.read(appPrimaryColorProvider.notifier).updateColor(config.primaryColor);
    await _ref.read(appTextColorProvider.notifier).updateColor(config.textColor);
    await _ref.read(appHighlightTextColorProvider.notifier).updateColor(config.highlightTextColor);
    
    // Layouts
    await _ref.read(homeSettingsProvider.notifier).setSettings(config.homeSettings);
    await _ref.read(profileSettingsProvider.notifier).setSettings(config.profileSettings);
    await _ref.read(bookingSettingsProvider.notifier).setSettings(config.bookingSettings);
  }
  
  AppConfig createConfigFromLocal() {
    final accent = _ref.read(appColorProvider);
    final primary = _ref.read(appPrimaryColorProvider);
    final text = _ref.read(appTextColorProvider);
    final highlight = _ref.read(appHighlightTextColorProvider);
    
    return AppConfig(
      accentColor: _colorToHex(accent),
      primaryColor: _colorToHex(primary),
      textColor: _colorToHex(text),
      highlightTextColor: _colorToHex(highlight),
      homeSettings: _ref.read(homeSettingsProvider),
      profileSettings: _ref.read(profileSettingsProvider),
      bookingSettings: _ref.read(bookingSettingsProvider),
    );
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }
}
