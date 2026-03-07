import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/models/booking_models.dart';
import '../../data/models/vehicle_models.dart';
import '../../data/models/user_models.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/local/preferences_manager.dart';

class BookingState {
  final int currentStep;
  final String pickupLocation;
  final String destination;
  final String pickupTimeType; // 'NOW' or 'SCHEDULE'
  final DateTime selectedDate;
  final String selectedTime;
  final List<Vehicle> availableVehicles;
  final Vehicle? selectedVehicle;
  final int passengers;
  final int luggage;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String additionalNote;
  final String paymentMethod;
  final String vehicleCategory;
  final String? distance;
  final String? duration;
  final List<Prediction> pickupSuggestions;
  final List<Prediction> destinationSuggestions;
  final List<LocationItem> savedPlaces;
  final List<LocationItem> recentDestinations;
  final List<PaymentGateway> paymentGateways;
  final bool isLoading;
  final String? error;
  final String? saveStatus;
  final BookingResponse? bookingStatus;
  final bool showAllRecent;
  final bool requiresPayment;
  final String? checkoutUrl;
  final String? paymentType;

  BookingState({
    this.currentStep = 0,
    this.pickupLocation = '',
    this.destination = '',
    this.pickupTimeType = 'NOW',
    DateTime? selectedDate,
    this.selectedTime = '',
    this.availableVehicles = const [],
    this.selectedVehicle,
    this.passengers = 1,
    this.luggage = 0,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.additionalNote = '',
    this.paymentMethod = '',
    this.vehicleCategory = 'All',
    this.distance,
    this.duration,
    this.pickupSuggestions = const [],
    this.destinationSuggestions = const [],
    this.savedPlaces = const [],
    this.recentDestinations = const [],
    this.paymentGateways = const [],
    this.isLoading = false,
    this.error,
    this.saveStatus,
    this.bookingStatus,
    this.showAllRecent = false,
    this.requiresPayment = false,
    this.checkoutUrl,
    this.paymentType,
  }) : selectedDate = selectedDate ?? DateTime.now();

  BookingState copyWith({
    int? currentStep,
    String? pickupLocation,
    String? destination,
    String? pickupTimeType,
    DateTime? selectedDate,
    String? selectedTime,
    List<Vehicle>? availableVehicles,
    Vehicle? selectedVehicle,
    int? passengers,
    int? luggage,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? additionalNote,
    String? paymentMethod,
    String? vehicleCategory,
    String? distance,
    String? duration,
    List<Prediction>? pickupSuggestions,
    List<Prediction>? destinationSuggestions,
    List<LocationItem>? savedPlaces,
    List<LocationItem>? recentDestinations,
    List<PaymentGateway>? paymentGateways,
    bool? isLoading,
    String? error,
    String? saveStatus,
    BookingResponse? bookingStatus,
    bool? showAllRecent,
    bool? requiresPayment,
    String? checkoutUrl,
    String? paymentType,
  }) {
    return BookingState(
      currentStep: currentStep ?? this.currentStep,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      pickupTimeType: pickupTimeType ?? this.pickupTimeType,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      passengers: passengers ?? this.passengers,
      luggage: luggage ?? this.luggage,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      additionalNote: additionalNote ?? this.additionalNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      pickupSuggestions: pickupSuggestions ?? this.pickupSuggestions,
      destinationSuggestions: destinationSuggestions ?? this.destinationSuggestions,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      recentDestinations: recentDestinations ?? this.recentDestinations,
      paymentGateways: paymentGateways ?? this.paymentGateways,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      saveStatus: saveStatus ?? this.saveStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      showAllRecent: showAllRecent ?? this.showAllRecent,
      requiresPayment: requiresPayment ?? this.requiresPayment,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      paymentType: paymentType ?? this.paymentType,
    );
  }
}

class BookingViewModel extends AsyncNotifier<BookingState> {
  Timer? _debounceTimer;

  @override
  Future<BookingState> build() async {
    _loadInitialData();
    return BookingState();
  }

  Future<void> _loadInitialData() async {
    state = const AsyncValue.loading();
    try {
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final bookingRepo = ref.read(bookingRepositoryProvider);
      
      final vehicles = await vehicleRepo.getVehicles();
      final gateways = await bookingRepo.getPaymentGateways();
      final recent = await bookingRepo.getRecentDestinations();
      final savedResponse = await bookingRepo.getSavedLocations();
      
      final List<LocationItem> savedPlaces = [];
      if (savedResponse.home != null) {
        savedPlaces.add(LocationItem(name: 'Home', address: savedResponse.home!));
      }
      if (savedResponse.work != null) {
        savedPlaces.add(LocationItem(name: 'Work', address: savedResponse.work!));
      }
      if (savedResponse.custom != null) {
        savedPlaces.addAll(savedResponse.custom!.map((e) => LocationItem(name: e.name, address: e.address)));
      }
      
      state = AsyncValue.data(BookingState(
        availableVehicles: vehicles,
        paymentGateways: gateways,
        recentDestinations: recent,
        savedPlaces: savedPlaces,
      ));
    } catch (e) {
      state = AsyncValue.data(BookingState(error: e.toString()));
    }
  }

  void updatePickupLocation(String value) {
    state = AsyncValue.data(state.value!.copyWith(pickupLocation: value, error: null));
    _fetchSuggestions(value, true);
  }

  void updateDestination(String value) {
    state = AsyncValue.data(state.value!.copyWith(destination: value, error: null));
    _fetchSuggestions(value, false);
  }

  void _fetchSuggestions(String input, bool isPickup) {
    _debounceTimer?.cancel();
    if (input.length < 3) {
      if (isPickup) {
        state = AsyncValue.data(state.value!.copyWith(pickupSuggestions: []));
      } else {
        state = AsyncValue.data(state.value!.copyWith(destinationSuggestions: []));
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        const apiKey = "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8";
        final response = await ref.read(apiServiceProvider).getAutocompleteSuggestions(input, apiKey);
        if (isPickup) {
          state = AsyncValue.data(state.value!.copyWith(pickupSuggestions: response.predictions));
        } else {
          state = AsyncValue.data(state.value!.copyWith(destinationSuggestions: response.predictions));
        }
      } catch (e) {
        // Handle error
      }
    });
  }

  void selectSuggestion(Prediction prediction, bool isPickup) {
    if (isPickup) {
      state = AsyncValue.data(state.value!.copyWith(
        pickupLocation: prediction.description,
        pickupSuggestions: [],
      ));
    } else {
      state = AsyncValue.data(state.value!.copyWith(
        destination: prediction.description,
        destinationSuggestions: [],
      ));
    }
    calculateDistance();
  }

  Future<void> calculateDistance() async {
    final s = state.value!;
    if (s.pickupLocation.isEmpty || s.destination.isEmpty) return;

    try {
      final response = await ref.read(bookingRepositoryProvider).getDistanceMatrix(s.pickupLocation, s.destination);
      if (response.status == 'OK' && response.rows.isNotEmpty) {
        final element = response.rows[0].elements[0];
        if (element.status == 'OK') {
          state = AsyncValue.data(state.value!.copyWith(
            distance: element.distance?.text,
            duration: element.duration?.text,
            error: null,
          ));
        } else if (element.status == 'ZERO_RESULTS') {
          state = AsyncValue.data(state.value!.copyWith(
            distance: null,
            duration: null,
            error: 'No driving route found between these locations.',
          ));
        } else {
          state = AsyncValue.data(state.value!.copyWith(
            distance: null,
            duration: null,
            error: 'Could not calculate distance: ${element.status}',
          ));
        }
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          distance: null,
          duration: null,
          error: 'Distance Matrix API Error: ${response.status}',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        distance: null,
        duration: null,
        error: 'Failed to calculate distance. Please try again.',
      ));
    }
  }

  void setPickupTimeType(String type) {
    state = AsyncValue.data(state.value!.copyWith(pickupTimeType: type));
  }

  void selectDate(DateTime date) {
    state = AsyncValue.data(state.value!.copyWith(selectedDate: date));
  }

  void selectTime(String time) {
    state = AsyncValue.data(state.value!.copyWith(selectedTime: time));
  }

  void selectVehicle(Vehicle vehicle) {
    state = AsyncValue.data(state.value!.copyWith(
      selectedVehicle: vehicle,
      passengers: 1, // Reset or cap existing
      luggage: 0,
    ));
  }

  void setVehicleCategory(String category) {
    state = AsyncValue.data(state.value!.copyWith(vehicleCategory: category));
  }

  void updatePassengers(int count) {
    final s = state.value!;
    final max = s.selectedVehicle?.passengers ?? 4;
    if (count >= 1 && count <= max) {
      state = AsyncValue.data(s.copyWith(passengers: count));
    }
  }

  void updateLuggage(int count) {
    final s = state.value!;
    final max = s.selectedVehicle?.luggage ?? 3;
    if (count >= 0 && count <= max) {
      state = AsyncValue.data(s.copyWith(luggage: count));
    }
  }

  void updateStep(int step) {
    state = AsyncValue.data(state.value!.copyWith(currentStep: step));
  }

  void nextStep(int totalSteps) {
    final current = state.value!.currentStep;
    if (current < totalSteps - 1) {
      updateStep(current + 1);
    }
  }

  void prevStep() {
    final current = state.value!.currentStep;
    if (current > 0) {
      updateStep(current - 1);
    }
  }

  Future<void> saveLocation(String label) async {
    final s = state.value!;
    if (s.pickupLocation.isEmpty) return;
    
    state = AsyncValue.data(s.copyWith(isLoading: true, saveStatus: null));
    try {
      await ref.read(bookingRepositoryProvider).addRecentDestination(s.pickupLocation);
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        saveStatus: 'Location saved as $label',
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> fetchCurrentLocation() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    try {
      final address = await ref.read(currentLocationProvider.future);
      state = AsyncValue.data(state.value!.copyWith(
        pickupLocation: address,
        isLoading: false,
      ));
      calculateDistance();
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectLocation(LocationItem item, bool isPickup) {
    if (isPickup) {
      state = AsyncValue.data(state.value!.copyWith(pickupLocation: item.address, pickupSuggestions: []));
    } else {
      state = AsyncValue.data(state.value!.copyWith(destination: item.address, destinationSuggestions: []));
    }
    calculateDistance();
  }

  void clearStatus() {
    state = AsyncValue.data(state.value!.copyWith(saveStatus: null, error: null));
  }

  void updateCustomerInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? note,
    String? paymentMethod,
  }) {
    state = AsyncValue.data(state.value!.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      additionalNote: note,
      paymentMethod: paymentMethod,
    ));
  }

  void toggleShowAllRecent() {
    state = AsyncValue.data(state.value!.copyWith(showAllRecent: !state.value!.showAllRecent));
  }

  Future<void> createBooking() async {
    final s = state.value!;
    if (s.selectedVehicle == null) return;

    state = AsyncValue.data(state.value!.copyWith(isLoading: true, error: null));
    try {
      final request = BookingRequest(
        vehicleId: int.parse(s.selectedVehicle!.id),
        pickupLocation: s.pickupLocation,
        dropoffLocation: s.destination,
        pickupDate: s.pickupTimeType == 'NOW' 
            ? DateTime.now().toString().split(' ')[0] 
            : s.selectedDate.toString().split(' ')[0],
        pickupTime: s.pickupTimeType == 'NOW' ? 'Now' : s.selectedTime,
        passengers: s.passengers,
        luggage: s.luggage,
        paymentGateway: s.paymentMethod,
        customerInfo: CustomerInfoDto(
          firstName: s.firstName,
          lastName: s.lastName,
          email: s.email,
          phone: s.phone,
          additionalNote: s.additionalNote.isEmpty ? null : s.additionalNote,
        ),
        totalPrice: s.selectedVehicle?.price,
        currency: s.selectedVehicle?.currency,
        timezone: 'UTC', // Default or fetch
      );

      final response = await ref.read(bookingRepositoryProvider).createBooking(request);
      
      if (response.success && response.requiresPayment == true) {
        final bookingId = response.bookingId!;
        final paymentMethod = s.paymentMethod.toLowerCase();
        
        if (paymentMethod.contains('stripe')) {
          final stripeSession = await ref.read(bookingRepositoryProvider).createStripeSession(bookingId);
          state = AsyncValue.data(state.value!.copyWith(
            isLoading: false,
            requiresPayment: true,
            checkoutUrl: stripeSession.url,
            paymentType: 'stripe',
            bookingStatus: response,
          ));
        } else if (paymentMethod.contains('paypal')) {
          final paypalOrder = await ref.read(bookingRepositoryProvider).createPayPalOrder(bookingId);
          state = AsyncValue.data(state.value!.copyWith(
            isLoading: false,
            requiresPayment: true,
            checkoutUrl: paypalOrder.approvalUrl,
            paymentType: 'paypal',
            bookingStatus: response,
          ));
        } else {
          // Fallback if requiresPayment is true but method is unknown
          state = AsyncValue.data(state.value!.copyWith(isLoading: false, bookingStatus: response));
        }
      } else {
        state = AsyncValue.data(state.value!.copyWith(isLoading: false, bookingStatus: response));
      }
      
      if (response.success) {
        ref.read(bookingRepositoryProvider).addRecentDestination(s.destination);
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> onStripeSuccess(String sessionId, int bookingId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, requiresPayment: false, checkoutUrl: null));
    try {
      final verifyResponse = await ref.read(bookingRepositoryProvider).verifyStripeSession(sessionId, bookingId);
      if (verifyResponse.success) {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          bookingStatus: BookingResponse(success: true, message: 'Payment successful', bookingId: bookingId),
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          error: verifyResponse.message ?? 'Payment verification failed',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> onPayPalSuccess(String token, int bookingId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, requiresPayment: false, checkoutUrl: null));
    try {
      final executeResponse = await ref.read(bookingRepositoryProvider).executePayPalPayment(token, bookingId);
      if (executeResponse.success) {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          bookingStatus: BookingResponse(success: true, message: 'Payment successful', bookingId: bookingId),
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          error: executeResponse.message,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void cancelPayment() {
    state = AsyncValue.data(state.value!.copyWith(requiresPayment: false, checkoutUrl: null));
  }
}

final bookingViewModelProvider = AsyncNotifierProvider<BookingViewModel, BookingState>(() {
  return BookingViewModel();
});
