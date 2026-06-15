import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/preferences_manager.dart';

enum ProfileSection {
  header,
  accountSettings,
  support,
  logout,
  footer,
}

class ProfileSettings {
  final List<ProfileSection> sections;
  final Map<ProfileSection, bool> visibility;

  ProfileSettings({
    required this.sections,
    required this.visibility,
  });

  factory ProfileSettings.defaultSettings() {
    return ProfileSettings(
      sections: [
        ProfileSection.header,
        ProfileSection.accountSettings,
        ProfileSection.support,
        ProfileSection.logout,
        ProfileSection.footer,
      ],
      visibility: {
        ProfileSection.header: true,
        ProfileSection.accountSettings: true,
        ProfileSection.support: true,
        ProfileSection.logout: true,
        ProfileSection.footer: true,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((e) => e.name).toList(),
      'visibility': visibility.map((k, v) => MapEntry(k.name, v)),
    };
  }

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    // Safe parsing helper for enums
    List<ProfileSection> safeParseSections(List? items) {
      if (items == null) return ProfileSettings.defaultSettings().sections;
      return items
          .map((e) {
            try {
              return ProfileSection.values.byName(e.toString());
            } catch (_) {
              return null;
            }
          })
          .whereType<ProfileSection>()
          .toList();
    }

    Map<ProfileSection, bool> safeParseVisibility(Map? vis) {
      if (vis == null) return ProfileSettings.defaultSettings().visibility;
      final result = <ProfileSection, bool>{};
      vis.forEach((k, v) {
        try {
          final section = ProfileSection.values.byName(k.toString());
          result[section] = v as bool;
        } catch (_) {
          // Skip invalid ones
        }
      });
      return result.isEmpty ? ProfileSettings.defaultSettings().visibility : result;
    }

    return ProfileSettings(
      sections: safeParseSections(json['sections'] as List?),
      visibility: safeParseVisibility(json['visibility'] as Map?),
    );
  }

  ProfileSettings copyWith({
    List<ProfileSection>? sections,
    Map<ProfileSection, bool>? visibility,
  }) {
    return ProfileSettings(
      sections: sections ?? this.sections,
      visibility: visibility ?? this.visibility,
    );
  }
}

final profileSettingsProvider = StateNotifierProvider<ProfileSettingsNotifier, ProfileSettings>((ref) {
  final prefs = ref.watch(preferencesManagerProvider);
  return ProfileSettingsNotifier(prefs);
});

class ProfileSettingsNotifier extends StateNotifier<ProfileSettings> {
  final PreferencesManager _prefs;
  static const _key = 'profile_settings';

  ProfileSettingsNotifier(this._prefs) : super(ProfileSettings.defaultSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final jsonString = _prefs.getString(_key);
    if (jsonString != null) {
      try {
        state = ProfileSettings.fromJson(json.decode(jsonString));
      } catch (_) {
        state = ProfileSettings.defaultSettings();
      }
    }
  }

  Future<void> setSettings(ProfileSettings settings) async {
    state = settings;
    await _saveSettings();
  }

  Future<void> updateVisibility(ProfileSection section, bool visible) async {
    final newVisibility = Map<ProfileSection, bool>.from(state.visibility);
    newVisibility[section] = visible;
    state = state.copyWith(visibility: newVisibility);
    await _saveSettings();
  }

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    final newSections = List<ProfileSection>.from(state.sections);
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
