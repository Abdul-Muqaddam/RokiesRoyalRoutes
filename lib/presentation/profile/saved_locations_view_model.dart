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
    // Watch the stream provider to make this notifier reactive to DB changes
    return ref.watch(savedLocationsStreamProvider.future);
  }

  Future<List<LocationItem>> _fetchLocations() async {
    final repository = ref.read(userRepositoryProvider);
    return await repository.getSavedLocations();
  }

  // Loading state for suggestions/actions
  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _error;
  String? get error => _error;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<void> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      ref.read(savedLocationSuggestionsProvider.notifier).state = [];
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repository = ref.read(userRepositoryProvider);
        final response = await repository.getAutocompleteSuggestions(input, _googleMapsApiKey);
        ref.read(savedLocationSuggestionsProvider.notifier).state = response.predictions;
      } catch (e) {
        // Silently fail suggestions
      }
    });
  }

  void clearSuggestions() {
    ref.read(savedLocationSuggestionsProvider.notifier).state = [];
  }

  Future<bool> saveLocation(String type, String address) async {
    if (address.isEmpty) {
      _error = 'Address cannot be empty';
      state = AsyncValue.data(state.value ?? []);
      return false;
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
        return true; // Indicate success
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      state = AsyncValue.data(state.value ?? []);
      return false;
    } finally {
      _isActionLoading = false;
      // We don't notify here to keep the error state visible
    }
  }

  Future<bool> saveCustomLocation(String label, String address) async {
    if (label.isEmpty || address.isEmpty) {
      _error = 'Label and address cannot be empty';
      state = AsyncValue.data(state.value ?? []);
      return false;
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
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      state = AsyncValue.data(state.value ?? []);
      return false;
    } finally {
      _isActionLoading = false;
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
      } else {
        _error = 'Failed to remove place';
      }
    } catch (e) {
      _error = e.toString();
      state = AsyncValue.data(state.value ?? []);
    } finally {
      _isActionLoading = false;
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

final savedLocationSuggestionsProvider = StateProvider<List<Prediction>>((ref) => []);

final savedLocationsStreamProvider = StreamProvider<List<LocationItem>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  
  // Create the stream
  final stream = repository.watchSavedLocations();
  
  // Add a side-effect for debugging and safety
  ref.listenSelf((previous, next) {
    next.when(
      data: (data) => print('DEBUG [savedLocationsStreamProvider]: Received ${data.length} locations'),
      error: (err, stack) {
        print('DEBUG [savedLocationsStreamProvider]: Error: $err');
        if (err.toString().contains('timedOut')) {
           print('DEBUG [Sync-Instruction]: ⚠️ Realtime Timeout detected.');
           print('DEBUG [Sync-Instruction]: ACTION REQUIRED: You must enable "Replication" for the "saved_locations" table in your Supabase Dashboard.');
           print('DEBUG [Sync-Instruction]: Path: Database -> Replication -> Source -> Toggle on "saved_locations".');
        }
      },
      loading: () => print('DEBUG [savedLocationsStreamProvider]: Loading...'),
    );
  });
  
  return stream;
});

final savedLocationsViewModelProvider = AsyncNotifierProvider<SavedLocationsViewModel, List<LocationItem>>(() {
  return SavedLocationsViewModel();
});
