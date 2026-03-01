import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/services/location_service.dart';

class SavedLocationsViewModel extends AsyncNotifier<List<LocationItem>> {
  static const String _googleMapsApiKey = "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8";
  Timer? _debounceTimer;

  @override
  Future<List<LocationItem>> build() async {
    return _fetchLocations();
  }

  Future<List<LocationItem>> _fetchLocations() async {
    final repository = ref.read(userRepositoryProvider);
    return await repository.getSavedLocations();
  }

  // State for suggestions
  List<Prediction> _suggestions = [];
  List<Prediction> get suggestions => _suggestions;

  // Loading state for suggestions/actions
  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _error;
  String? get error => _error;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<void> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      _suggestions = [];
      state = AsyncValue.data(state.value ?? []);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repository = ref.read(userRepositoryProvider);
        final response = await repository.getAutocompleteSuggestions(input, _googleMapsApiKey);
        _suggestions = response.predictions;
        state = AsyncValue.data(state.value ?? []);
      } catch (e) {
        // Silently fail suggestions
      }
    });
  }

  void clearSuggestions() {
    _suggestions = [];
    state = AsyncValue.data(state.value ?? []);
  }

  Future<void> saveLocation(String type, String address) async {
    if (address.isEmpty) {
      _error = 'Address cannot be empty';
      state = AsyncValue.data(state.value ?? []);
      return;
    }

    _isActionLoading = true;
    _error = null;
    state = AsyncValue.data(state.value ?? []);

    try {
      final repository = ref.read(userRepositoryProvider);
      final request = type.toLowerCase() == 'home' 
          ? UpdateLocationsRequest(home: address) 
          : UpdateLocationsRequest(work: address);
      
      final response = await repository.updateSavedLocations(request);
      if (response.success) {
        _successMessage = 'Location updated successfully';
        state = AsyncValue.data(await _fetchLocations());
      } else {
        _error = response.message;
        state = AsyncValue.data(state.value ?? []);
      }
    } catch (e) {
      _error = e.toString();
      state = AsyncValue.data(state.value ?? []);
    } finally {
      _isActionLoading = false;
      state = AsyncValue.data(state.value ?? []);
    }
  }

  Future<void> saveCustomLocation(String label, String address) async {
    if (label.isEmpty || address.isEmpty) {
      _error = 'Label and address cannot be empty';
      state = AsyncValue.data(state.value ?? []);
      return;
    }

    _isActionLoading = true;
    _error = null;
    state = AsyncValue.data(state.value ?? []);

    try {
      final repository = ref.read(userRepositoryProvider);
      final currentLocations = state.value ?? [];
      
      final customPlaces = currentLocations
          .where((l) => l.name != 'Home' && l.name != 'Work' && l.name.toLowerCase() != label.toLowerCase())
          .map((l) => CustomPlace(name: l.name, address: l.address))
          .toList();
      
      customPlaces.add(CustomPlace(name: label, address: address));
      
      final request = UpdateLocationsRequest(custom: customPlaces);
      final response = await repository.updateSavedLocations(request);
      
      if (response.success) {
        _successMessage = "'$label' saved!";
        state = AsyncValue.data(await _fetchLocations());
      } else {
        _error = response.message;
        state = AsyncValue.data(state.value ?? []);
      }
    } catch (e) {
      _error = e.toString();
      state = AsyncValue.data(state.value ?? []);
    } finally {
      _isActionLoading = false;
      state = AsyncValue.data(state.value ?? []);
    }
  }

  Future<void> deleteCustomLocation(LocationItem item) async {
    _isActionLoading = true;
    _error = null;
    state = AsyncValue.data(state.value ?? []);

    try {
      final repository = ref.read(userRepositoryProvider);
      final currentLocations = state.value ?? [];
      
      final customOnly = currentLocations
          .where((l) => l.name != 'Home' && l.name != 'Work' && l.name != item.name)
          .map((l) => CustomPlace(name: l.name, address: l.address))
          .toList();
      
      final request = UpdateLocationsRequest(custom: customOnly);
      final response = await repository.updateSavedLocations(request);
      
      if (response.success) {
        _successMessage = 'Place removed: ${item.name}';
        state = AsyncValue.data(await _fetchLocations());
      } else {
        _error = 'Failed to remove place';
        state = AsyncValue.data(state.value ?? []);
      }
    } catch (e) {
      _error = e.toString();
      state = AsyncValue.data(state.value ?? []);
    } finally {
      _isActionLoading = false;
      state = AsyncValue.data(state.value ?? []);
    }
  }

  Future<String?> getCurrentAddress() async {
    final locationService = ref.read(locationServiceProvider);
    return await locationService.getCurrentLocationName();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    state = AsyncValue.data(state.value ?? []);
  }
}

final savedLocationsViewModelProvider = AsyncNotifierProvider<SavedLocationsViewModel, List<LocationItem>>(() {
  return SavedLocationsViewModel();
});
