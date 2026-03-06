import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/preferences_manager.dart';

enum HomeSection {
  header,
  bookingCard,
  vehicleSelector,
  upcomingTrip,
  quickServices,
}

class HomeSettings {
  final List<HomeSection> sections;
  final Map<HomeSection, bool> visibility;

  HomeSettings({
    required this.sections,
    required this.visibility,
  });

  factory HomeSettings.defaultSettings() {
    return HomeSettings(
      sections: [
        HomeSection.header,
        HomeSection.bookingCard,
        HomeSection.vehicleSelector,
        HomeSection.upcomingTrip,
        HomeSection.quickServices,
      ],
      visibility: {
        HomeSection.header: true,
        HomeSection.bookingCard: true,
        HomeSection.vehicleSelector: true,
        HomeSection.upcomingTrip: true,
        HomeSection.quickServices: true,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((e) => e.name).toList(),
      'visibility': visibility.map((k, v) => MapEntry(k.name, v)),
    };
  }

  factory HomeSettings.fromJson(Map<String, dynamic> json) {
    return HomeSettings(
      sections: (json['sections'] as List).map((e) => HomeSection.values.byName(e)).toList(),
      visibility: (json['visibility'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(HomeSection.values.byName(k), v as bool),
      ),
    );
  }

  HomeSettings copyWith({
    List<HomeSection>? sections,
    Map<HomeSection, bool>? visibility,
  }) {
    return HomeSettings(
      sections: sections ?? this.sections,
      visibility: visibility ?? this.visibility,
    );
  }
}

final homeSettingsProvider = StateNotifierProvider<HomeSettingsNotifier, HomeSettings>((ref) {
  final prefs = ref.watch(preferencesManagerProvider);
  return HomeSettingsNotifier(prefs);
});

class HomeSettingsNotifier extends StateNotifier<HomeSettings> {
  final PreferencesManager _prefs;
  static const _key = 'home_settings';

  HomeSettingsNotifier(this._prefs) : super(HomeSettings.defaultSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final jsonString = _prefs.getString(_key);
    if (jsonString != null) {
      try {
        state = HomeSettings.fromJson(json.decode(jsonString));
      } catch (_) {
        state = HomeSettings.defaultSettings();
      }
    }
  }

  Future<void> setSettings(HomeSettings settings) async {
    state = settings;
    await _saveSettings();
  }

  Future<void> updateVisibility(HomeSection section, bool visible) async {
    final newVisibility = Map<HomeSection, bool>.from(state.visibility);
    newVisibility[section] = visible;
    state = state.copyWith(visibility: newVisibility);
    await _saveSettings();
  }

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    final newSections = List<HomeSection>.from(state.sections);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = newSections.removeAt(oldIndex);
    newSections.insert(newIndex, item);
    state = state.copyWith(sections: newSections);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    await _prefs.setString(_key, json.encode(state.toJson()));
  }
}
