import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/preferences_manager.dart';

enum BookingStep1Section { header, locationFields, recentPlaces, savedPlaces, distanceCard, saveLocation }
enum BookingStep2Section { timeType, dateSelector, timeGrid, customTime, infoBox }
enum BookingStep3Section { categoryTabs, vehicleList }
enum BookingStep4Section { summaryCard, tripDetails, personalDetails, noteField, paymentMethods, requirements }
enum BookingStep { locations, time, vehicle, summary }

class BookingSettings {
  final List<BookingStep> steps;
  final Map<BookingStep, bool> visibility;
  
  final List<BookingStep1Section> step1Order;
  final Map<BookingStep1Section, bool> step1Visibility;
  
  final List<BookingStep2Section> step2Order;
  final Map<BookingStep2Section, bool> step2Visibility;
  
  final List<BookingStep3Section> step3Order;
  final Map<BookingStep3Section, bool> step3Visibility;
  
  final List<BookingStep4Section> step4Order;
  final Map<BookingStep4Section, bool> step4Visibility;

  BookingSettings({
    required this.steps,
    required this.visibility,
    required this.step1Order,
    required this.step1Visibility,
    required this.step2Order,
    required this.step2Visibility,
    required this.step3Order,
    required this.step3Visibility,
    required this.step4Order,
    required this.step4Visibility,
  });

  factory BookingSettings.defaultSettings() {
    return BookingSettings(
      steps: BookingStep.values.toList(),
      visibility: { for (var v in BookingStep.values) v: true },
      
      step1Order: BookingStep1Section.values.toList(),
      step1Visibility: { for (var v in BookingStep1Section.values) v: true },
      
      step2Order: BookingStep2Section.values.toList(),
      step2Visibility: { for (var v in BookingStep2Section.values) v: true },
      
      step3Order: BookingStep3Section.values.toList(),
      step3Visibility: { for (var v in BookingStep3Section.values) v: true },
      
      step4Order: BookingStep4Section.values.toList(),
      step4Visibility: { for (var v in BookingStep4Section.values) v: true },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((e) => e.name).toList(),
      'visibility': visibility.map((k, v) => MapEntry(k.name, v)),
      'step1Order': step1Order.map((e) => e.name).toList(),
      'step1Visibility': step1Visibility.map((k, v) => MapEntry(k.name, v)),
      'step2Order': step2Order.map((e) => e.name).toList(),
      'step2Visibility': step2Visibility.map((k, v) => MapEntry(k.name, v)),
      'step3Order': step3Order.map((e) => e.name).toList(),
      'step3Visibility': step3Visibility.map((k, v) => MapEntry(k.name, v)),
      'step4Order': step4Order.map((e) => e.name).toList(),
      'step4Visibility': step4Visibility.map((k, v) => MapEntry(k.name, v)),
    };
  }

  factory BookingSettings.fromJson(Map<String, dynamic> json) {
    return BookingSettings(
      steps: (json['steps'] as List?)?.map((e) => BookingStep.values.byName(e)).toList() ?? BookingStep.values.toList(),
      visibility: (json['visibility'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(BookingStep.values.byName(k), v as bool)) ?? { for (var v in BookingStep.values) v: true },
      
      step1Order: (json['step1Order'] as List).map((e) => BookingStep1Section.values.byName(e)).toList(),
      step1Visibility: (json['step1Visibility'] as Map<String, dynamic>).map((k, v) => MapEntry(BookingStep1Section.values.byName(k), v as bool)),
      
      step2Order: (json['step2Order'] as List).map((e) => BookingStep2Section.values.byName(e)).toList(),
      step2Visibility: (json['step2Visibility'] as Map<String, dynamic>).map((k, v) => MapEntry(BookingStep2Section.values.byName(k), v as bool)),
      
      step3Order: (json['step3Order'] as List).map((e) => BookingStep3Section.values.byName(e)).toList(),
      step3Visibility: (json['step3Visibility'] as Map<String, dynamic>).map((k, v) => MapEntry(BookingStep3Section.values.byName(k), v as bool)),
      
      step4Order: (json['step4Order'] as List).map((e) => BookingStep4Section.values.byName(e)).toList(),
      step4Visibility: (json['step4Visibility'] as Map<String, dynamic>).map((k, v) => MapEntry(BookingStep4Section.values.byName(k), v as bool)),
    );
  }

  BookingSettings copyWith({
    List<BookingStep>? steps,
    Map<BookingStep, bool>? visibility,
    List<BookingStep1Section>? step1Order,
    Map<BookingStep1Section, bool>? step1Visibility,
    List<BookingStep2Section>? step2Order,
    Map<BookingStep2Section, bool>? step2Visibility,
    List<BookingStep3Section>? step3Order,
    Map<BookingStep3Section, bool>? step3Visibility,
    List<BookingStep4Section>? step4Order,
    Map<BookingStep4Section, bool>? step4Visibility,
  }) {
    return BookingSettings(
      steps: steps ?? this.steps,
      visibility: visibility ?? this.visibility,
      step1Order: step1Order ?? this.step1Order,
      step1Visibility: step1Visibility ?? this.step1Visibility,
      step2Order: step2Order ?? this.step2Order,
      step2Visibility: step2Visibility ?? this.step2Visibility,
      step3Order: step3Order ?? this.step3Order,
      step3Visibility: step3Visibility ?? this.step3Visibility,
      step4Order: step4Order ?? this.step4Order,
      step4Visibility: step4Visibility ?? this.step4Visibility,
    );
  }
}

final bookingSettingsProvider = StateNotifierProvider<BookingSettingsNotifier, BookingSettings>((ref) {
  final prefs = ref.watch(preferencesManagerProvider);
  return BookingSettingsNotifier(prefs);
});

class BookingSettingsNotifier extends StateNotifier<BookingSettings> {
  final PreferencesManager _prefs;
  static const _key = 'booking_granular_settings';

  BookingSettingsNotifier(this._prefs) : super(BookingSettings.defaultSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final jsonString = _prefs.getString(_key);
    if (jsonString != null) {
      try {
        state = BookingSettings.fromJson(json.decode(jsonString));
      } catch (_) {
        state = BookingSettings.defaultSettings();
      }
    }
  }

  Future<void> setSettings(BookingSettings settings) async {
    state = settings;
    await _saveSettings();
  }

  Future<void> updateVisibility(int stepIndex, dynamic section, bool visible) async {
    if (stepIndex == 1) {
      final newVisibility = Map<BookingStep1Section, bool>.from(state.step1Visibility);
      newVisibility[section as BookingStep1Section] = visible;
      state = state.copyWith(step1Visibility: newVisibility);
    } else if (stepIndex == 2) {
      final newVisibility = Map<BookingStep2Section, bool>.from(state.step2Visibility);
      newVisibility[section as BookingStep2Section] = visible;
      state = state.copyWith(step2Visibility: newVisibility);
    } else if (stepIndex == 3) {
      final newVisibility = Map<BookingStep3Section, bool>.from(state.step3Visibility);
      newVisibility[section as BookingStep3Section] = visible;
      state = state.copyWith(step3Visibility: newVisibility);
    } else if (stepIndex == 4) {
      final newVisibility = Map<BookingStep4Section, bool>.from(state.step4Visibility);
      newVisibility[section as BookingStep4Section] = visible;
      state = state.copyWith(step4Visibility: newVisibility);
    }
    await _saveSettings();
  }

  Future<void> reorderSections(int stepIndex, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    
    if (stepIndex == 1) {
      final newList = List<BookingStep1Section>.from(state.step1Order);
      final item = newList.removeAt(oldIndex);
      newList.insert(newIndex, item);
      state = state.copyWith(step1Order: newList);
    } else if (stepIndex == 2) {
      final newList = List<BookingStep2Section>.from(state.step2Order);
      final item = newList.removeAt(oldIndex);
      newList.insert(newIndex, item);
      state = state.copyWith(step2Order: newList);
    } else if (stepIndex == 3) {
      final newList = List<BookingStep3Section>.from(state.step3Order);
      final item = newList.removeAt(oldIndex);
      newList.insert(newIndex, item);
      state = state.copyWith(step3Order: newList);
    } else if (stepIndex == 4) {
      final newList = List<BookingStep4Section>.from(state.step4Order);
      final item = newList.removeAt(oldIndex);
      newList.insert(newIndex, item);
      state = state.copyWith(step4Order: newList);
    }
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    await _prefs.setString(_key, json.encode(state.toJson()));
  }
}
