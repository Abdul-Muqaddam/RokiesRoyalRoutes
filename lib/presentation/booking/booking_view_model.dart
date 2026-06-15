import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/models/booking_models.dart';
import '../../data/models/vehicle_models.dart';
import '../../data/models/user_models.dart';
import '../../domain/repositories/booking_repository.dart' hide savedLocationsStreamProvider;
import '../../data/repositories/vehicle_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/local/preferences_manager.dart';
import '../profile/saved_locations_view_model.dart';
import '../../data/services/stripe_service.dart';
import '../../data/services/paypal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../wallet/wallet_view_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/services/push_notification_service.dart';

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
  final bool showAllSavedPlaces;
  final bool requiresPayment;
  final String? checkoutUrl;
  final String? paymentType;
  final bool isFlightMode;

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
    this.showAllSavedPlaces = false,
    this.requiresPayment = false,
    this.checkoutUrl,
    this.paymentType,
    this.isFlightMode = false,
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
    bool? showAllSavedPlaces,
    bool? requiresPayment,
    String? checkoutUrl,
    String? paymentType,
    bool? isFlightMode,
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
      showAllSavedPlaces: showAllSavedPlaces ?? this.showAllSavedPlaces,
      requiresPayment: requiresPayment ?? this.requiresPayment,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      paymentType: paymentType ?? this.paymentType,
      isFlightMode: isFlightMode ?? this.isFlightMode,
    );
  }
}

class BookingViewModel extends AsyncNotifier<BookingState> {
  Timer? _debounceTimer;

  @override
  Future<BookingState> build() async {
    _loadInitialData();
    
    // Watch the saved locations stream to keep the booking state updated in real-time
    ref.listen<AsyncValue<List<LocationItem>>>(savedLocationsStreamProvider, (prev, next) {
      next.whenData((locations) {
        if (state.hasValue) {
          final s = state.value ?? BookingState();
          state = AsyncValue.data(s.copyWith(savedPlaces: locations));
        }
      });
    });

    // Watch for vehicle updates
    ref.listen<AsyncValue<List<Vehicle>>>(allVehiclesProvider, (prev, next) {
      next.whenData((vehicles) {
        if (state.hasValue) {
          final s = state.value ?? BookingState();
          state = AsyncValue.data(s.copyWith(availableVehicles: vehicles));
        }
      });
    });

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
      
      final currentState = state.value ?? BookingState();
      state = AsyncValue.data(currentState.copyWith(
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
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(
      pickupLocation: value, 
      error: null,
      distance: null, 
      duration: null,
      isFlightMode: false,
    ));
    _fetchSuggestions(value, true);
  }

  void updateDestination(String value) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(
      destination: value, 
      error: null,
      distance: null, 
      duration: null,
      isFlightMode: false,
    ));
    _fetchSuggestions(value, false);
  }

  void _fetchSuggestions(String input, bool isPickup) {
    _debounceTimer?.cancel();
    if (input.length < 3) {
      if (isPickup) {
        final s = state.value ?? BookingState();
        state = AsyncValue.data(s.copyWith(pickupSuggestions: []));
      } else {
        final s = state.value ?? BookingState();
        state = AsyncValue.data(s.copyWith(destinationSuggestions: []));
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        const apiKey = "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8";
        final response = await ref.read(userRepositoryProvider).getAutocompleteSuggestions(input, apiKey);
        if (isPickup) {
          final s = state.value ?? BookingState();
          state = AsyncValue.data(s.copyWith(pickupSuggestions: response.predictions));
        } else {
          final s = state.value ?? BookingState();
          state = AsyncValue.data(s.copyWith(destinationSuggestions: response.predictions));
        }
      } catch (e) {
        // Handle error
      }
    });
  }

  void selectSuggestion(Prediction prediction, bool isPickup) {
    final s = state.value ?? BookingState();
    if (isPickup) {
      state = AsyncValue.data(s.copyWith(
        pickupLocation: prediction.description,
        pickupSuggestions: [],
        distance: null,
        duration: null,
        isFlightMode: false,
      ));
    } else {
      state = AsyncValue.data(s.copyWith(
        destination: prediction.description,
        destinationSuggestions: [],
        distance: null,
        duration: null,
        isFlightMode: false,
      ));
    }
  }

  Future<void> calculateDistance() async {
    final s = state.value ?? BookingState();
    if (s.pickupLocation.isEmpty || s.destination.isEmpty) return;

    state = AsyncValue.data(s.copyWith(isLoading: true, error: null));

    try {
      final pickupCoordsList = parseLatLngFromString(s.pickupLocation);
      final destCoordsList = parseLatLngFromString(s.destination);

      double? pLat, pLng, dLat, dLng;
      if (pickupCoordsList != null) {
        pLat = pickupCoordsList[0];
        pLng = pickupCoordsList[1];
      } else {
        try {
          final locs = await locationFromAddress(cleanLocationName(s.pickupLocation));
          if (locs.isNotEmpty) {
            pLat = locs.first.latitude;
            pLng = locs.first.longitude;
          }
        } catch (_) {}
      }

      if (destCoordsList != null) {
        dLat = destCoordsList[0];
        dLng = destCoordsList[1];
      } else {
        try {
          final locs = await locationFromAddress(cleanLocationName(s.destination));
          if (locs.isNotEmpty) {
            dLat = locs.first.latitude;
            dLng = locs.first.longitude;
          }
        } catch (_) {}
      }

      if (s.isFlightMode == true) {
        if (pLat != null && pLng != null && dLat != null && dLng != null) {
          final distanceInMeters = Geolocator.distanceBetween(pLat, pLng, dLat, dLng);
          final distanceInKm = distanceInMeters / 1000;
          
          final s2 = state.value ?? BookingState();
          state = AsyncValue.data(s2.copyWith(
            distance: '${distanceInKm.toStringAsFixed(1)} km (Air)',
            duration: 'N/A',
            isLoading: false,
            error: null,
          ));
          return;
        }
      }

      final String originStr = (pLat != null && pLng != null) ? "$pLat,$pLng" : cleanLocationName(s.pickupLocation);
      final String destStr = (dLat != null && dLng != null) ? "$dLat,$dLng" : cleanLocationName(s.destination);

      final response = await ref.read(bookingRepositoryProvider).getDistanceMatrix(originStr, destStr);
      if (response.status == 'OK' && response.rows.isNotEmpty) {
        final element = response.rows[0].elements[0];
        if (element.status == 'OK') {
          final s = state.value ?? BookingState();
          state = AsyncValue.data(s.copyWith(
            distance: element.distance?.text,
            duration: element.duration?.text,
            isLoading: false,
            error: null,
          ));
        } else if (element.status == 'ZERO_RESULTS') {
          final s = state.value ?? BookingState();
          state = AsyncValue.data(s.copyWith(
            distance: null,
            duration: null,
            isLoading: false,
            error: 'No driving route found. Would you like to use Flight Mode?',
          ));
        } else {
          final s = state.value ?? BookingState();
          state = AsyncValue.data(s.copyWith(
            distance: null,
            duration: null,
            isLoading: false,
            error: 'Could not calculate distance: ${element.status}',
          ));
        }
      } else {
        final s = state.value ?? BookingState();
        state = AsyncValue.data(s.copyWith(
          distance: null,
          duration: null,
          isLoading: false,
          error: 'Distance Matrix API Error: ${response.status}',
        ));
      }
    } catch (e) {
      final s = state.value ?? BookingState();
      state = AsyncValue.data(s.copyWith(
        distance: null,
        duration: null,
        isLoading: false,
        error: 'Failed to calculate distance. Please try again.',
      ));
    }
  }

  void setPickupTimeType(String type) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(pickupTimeType: type));
  }

  void updateDate(DateTime date) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(
      selectedDate: date,
      bookingStatus: null, // Clear previous success status
    ));
  }

  void updateTime(String time) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(
      selectedTime: time,
      bookingStatus: null, // Clear previous success status
    ));
  }

  void selectVehicle(Vehicle vehicle) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(
      selectedVehicle: vehicle,
      passengers: 1, // Reset or cap existing
      luggage: 0,
      bookingStatus: null, // Clear previous success status
      requiresPayment: false,
      checkoutUrl: null,
    ));
  }

  void setVehicleCategory(String category) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(vehicleCategory: category));
  }

  void updatePassengers(int count) {
    final s = state.value ?? BookingState();
    final max = s.selectedVehicle?.passengers ?? 4;
    if (count >= 1 && count <= max) {
      state = AsyncValue.data(s.copyWith(passengers: count));
    }
  }

  void updateLuggage(int count) {
    final s = state.value ?? BookingState();
    final max = s.selectedVehicle?.luggage ?? 3;
    if (count >= 0 && count <= max) {
      state = AsyncValue.data(s.copyWith(luggage: count));
    }
  }

  void updateStep(int step) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(currentStep: step));
  }

  Future<void> nextStep(int totalSteps) async {
    final currentState = state.value ?? BookingState();
    final current = currentState.currentStep;

    if (current < totalSteps - 1) {
      updateStep(current + 1);
    }
  }

  void prevStep() {
    final s = state.value ?? BookingState();
    final current = s.currentStep;
    if (current > 0) {
      updateStep(current - 1);
    }
  }

  Future<void> saveLocation(String label) async {
    final s = state.value ?? BookingState();
    if (s.pickupLocation.isEmpty) return;
    
    state = AsyncValue.data(s.copyWith(isLoading: true, saveStatus: null));
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final type = label.toLowerCase();
      
      UpdateLocationsRequest request;
      if (type == 'home') {
        request = UpdateLocationsRequest(home: s.pickupLocation);
      } else if (type == 'work') {
        request = UpdateLocationsRequest(work: s.pickupLocation);
      } else {
        // For custom places, we need to fetch existing and add
        final currentLocations = await userRepo.getSavedLocations();
        final customPlaces = currentLocations
            .where((l) => l.name != 'Home' && l.name != 'Work' && l.name.toLowerCase() != type)
            .map((l) => CustomPlace(name: l.name, address: l.address))
            .toList();
        
        customPlaces.add(CustomPlace(name: label, address: s.pickupLocation));
        request = UpdateLocationsRequest(custom: customPlaces);
      }

      final response = await userRepo.updateSavedLocations(request);
      
      if (response.success) {
        final s = state.value ?? BookingState();
        state = AsyncValue.data(s.copyWith(
          isLoading: false,
          saveStatus: 'Location saved as $label',
        ));
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      final s = state.value ?? BookingState();
      state = AsyncValue.data(s.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> fetchCurrentLocation() async {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(isLoading: true));
    try {
      final address = await ref.read(currentLocationProvider.future);
      final s = state.value ?? BookingState();
      state = AsyncValue.data(s.copyWith(
        pickupLocation: address,
        isLoading: false,
        distance: null,
        duration: null,
        isFlightMode: false,
      ));
    } catch (e) {
      final s_safe = state.value ?? BookingState();
          state = AsyncValue.data(s_safe.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectLocation(LocationItem item, bool isPickup) {
    final s = state.value ?? BookingState();
    if (isPickup) {
      state = AsyncValue.data(s.copyWith(
        pickupLocation: item.address, 
        pickupSuggestions: [],
        distance: null,
        duration: null,
        isFlightMode: false,
      ));
    } else {
      state = AsyncValue.data(s.copyWith(
        destination: item.address, 
        destinationSuggestions: [],
        distance: null,
        duration: null,
        isFlightMode: false,
      ));
    }
  }

  void clearStatus() {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(saveStatus: null, error: null));
  }

  void updateCustomerInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? note,
    String? paymentMethod,
  }) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      additionalNote: note,
      paymentMethod: paymentMethod,
    ));
  }

  void toggleShowAllRecent() {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(showAllRecent: !s.showAllRecent));
  }

  void setFlightMode(bool enabled) {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(
      isFlightMode: enabled,
      error: enabled ? null : s.error,
    ));

    if (enabled) {
      calculateDistance();
    }
  }

  void toggleShowAllSavedPlaces() {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(showAllSavedPlaces: !s.showAllSavedPlaces));
  }

  Future<void> createBooking({BuildContext? context}) async {
    final s = state.value ?? BookingState();
    if (s.selectedVehicle == null) return;
    
    state = AsyncValue.data(s.copyWith(isLoading: true, error: null));
    try {
      // Resolve "Current location" to a real geocodable address if needed
      String pickup = s.pickupLocation;
      if (pickup == 'Current location' || pickup.isEmpty) {
        final resolved = await ref.read(locationServiceProvider).getCurrentLocationName();
        if (resolved != null && resolved.isNotEmpty && resolved != 'Permission denied') {
          pickup = resolved;
        }
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          pickup = '$pickup (${pos.latitude}, ${pos.longitude})';
        } catch (_) {}
      } else {
        if (!pickup.contains(RegExp(r'\(([^,]+),\s*([^)]+)\)'))) {
          try {
            final locs = await locationFromAddress(cleanLocationName(pickup));
            if (locs.isNotEmpty) {
              pickup = '${cleanLocationName(pickup)} (${locs.first.latitude}, ${locs.first.longitude})';
            }
          } catch (_) {}
        }
      }

      String destination = s.destination;
      if (destination.isNotEmpty && !destination.contains(RegExp(r'\(([^,]+),\s*([^)]+)\)'))) {
        try {
          final locs = await locationFromAddress(cleanLocationName(destination));
          if (locs.isNotEmpty) {
            destination = '${cleanLocationName(destination)} (${locs.first.latitude}, ${locs.first.longitude})';
          }
        } catch (_) {}
      }

      // ── Step 1: Build booking request ─────────────────────────────────────
      final request = BookingRequest(
        vehicleId: s.selectedVehicle!.id,
        pickupLocation: pickup,
        dropoffLocation: destination,
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
        timezone: 'UTC',
      );

      // ── Step 2: Create booking in Supabase (status: pending) ───────────────
      final response = await ref.read(bookingRepositoryProvider).createBooking(request);

      if (!response.success) {
        final s2 = state.value ?? BookingState();
        state = AsyncValue.data(s2.copyWith(
          isLoading: false,
          error: response.message,
        ));
        return;
      }

      final bookingId = response.bookingId!;
      final s3 = state.value ?? BookingState();
      final paymentMethod = s3.paymentMethod.toLowerCase();

      // ── Step 3: Handle payment ─────────────────────────────────────────────
      if (paymentMethod.contains('stripe')) {
        // Native Stripe Payment Sheet Flow
        if (context == null || !context.mounted) {
          final s_safe = state.value ?? BookingState();
          state = AsyncValue.data(s_safe.copyWith(
            isLoading: false,
            error: 'Payment context unavailable',
          ));
          return;
        }

        final totalPrice = double.tryParse(s.selectedVehicle?.price?.toString() ?? '0') ?? 0.0;
        final currency = s.selectedVehicle?.currency ?? 'usd';

        try {
          final success = await StripeService.processStripePayment(
            context: context,
            totalPrice: totalPrice,
            currency: currency,
            bookingId: bookingId,
          );

          if (success) {
            // Payment succeeded → mark booking success
            ref.read(bookingRepositoryProvider).addRecentDestination(s.destination);
            ref.invalidate(bookingsStreamProvider);
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              ref.read(notificationRepositoryProvider).insert(
                userId: userId,
                title: 'Booking Placed Successfully!',
                body: 'Your booking #${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId} to ${s.destination} is placed and pending confirmation.',
                type: 'booking',
              ).catchError((e) => debugPrint('Note: Error inserting notification: $e'));
            }
            _triggerPushNotifications(bookingId, s.destination);
            final s5 = state.value ?? BookingState();
            state = AsyncValue.data(s5.copyWith(
              isLoading: false,
              bookingStatus: BookingResponse(
                success: true,
                message: 'Payment successful',
                bookingId: bookingId,
              ),
            ));
          } else {
            // User cancelled or payment failed in WebView
            final s6 = state.value ?? BookingState();
            state = AsyncValue.data(s6.copyWith(
              isLoading: false,
              error: 'Payment cancelled or failed',
            ));
          }
        } on StripeException catch (e) {
          // User cancelled or card declined
          final msg = e.error.localizedMessage ?? e.error.message ?? 'Payment cancelled';
          final s6 = state.value ?? BookingState();
          state = AsyncValue.data(s6.copyWith(
            isLoading: false,
            error: msg,
          ));
        }
      } else if (paymentMethod.contains('paypal')) {
        // Native PayPal Checkout Flow
        if (context == null || !context.mounted) {
          final s_safe = state.value ?? BookingState();
          state = AsyncValue.data(s_safe.copyWith(
            isLoading: false,
            error: 'Payment context unavailable',
          ));
          return;
        }

        final totalPrice = double.tryParse(s.selectedVehicle?.price?.toString() ?? '0') ?? 0.0;
        final currency = s.selectedVehicle?.currency ?? 'usd';

        PaypalService.processPaypalPayment(
          context: context,
          totalPrice: totalPrice,
          currency: currency,
          bookingId: bookingId,
          onSuccess: () {
            ref.read(bookingRepositoryProvider).addRecentDestination(s.destination);
            ref.invalidate(bookingsStreamProvider);
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              ref.read(notificationRepositoryProvider).insert(
                userId: userId,
                title: 'Booking Placed Successfully!',
                body: 'Your booking #${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId} to ${s.destination} is placed and pending confirmation.',
                type: 'booking',
              ).catchError((e) => debugPrint('Note: Error inserting notification: $e'));
            }
            _triggerPushNotifications(bookingId, s.destination);
            final s8 = state.value ?? BookingState();
            state = AsyncValue.data(s8.copyWith(
              isLoading: false,
              requiresPayment: false,
              checkoutUrl: null,
              bookingStatus: BookingResponse(
                success: true,
                message: 'Payment successful',
                bookingId: bookingId,
              ),
            ));
          },
          onCancel: () {
            final s9 = state.value ?? BookingState();
            state = AsyncValue.data(s9.copyWith(
              isLoading: false,
              requiresPayment: false,
              checkoutUrl: null,
              error: 'PayPal Checkout cancelled.',
            ));
          },
          onError: (errorMsg) {
            final s10 = state.value ?? BookingState();
            state = AsyncValue.data(s10.copyWith(
              isLoading: false,
              requiresPayment: false,
              checkoutUrl: null,
              error: 'PayPal Error: $errorMsg',
            ));
          },
        );
      } else if (paymentMethod.contains('wallet')) {
        // Handle Wallet Payment
        final totalPrice = double.tryParse(s.selectedVehicle?.price?.toString() ?? '0') ?? 0.0;
        try {
          await ref.read(userRepositoryProvider).deductWalletBalance(
            totalPrice,
            title: 'Ride Payment',
            description: 'Payment for booking to ${s.destination}',
          );
          
          // Refresh user profile to reflect new balance
          await ref.refresh(userProfileProvider.future);
          ref.invalidate(walletViewModelProvider);
          
          // Mark booking success
          ref.read(bookingRepositoryProvider).addRecentDestination(s.destination);
          ref.invalidate(bookingsStreamProvider);
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            ref.read(notificationRepositoryProvider).insert(
              userId: userId,
              title: 'Booking Placed Successfully!',
              body: 'Your booking #${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId} to ${s.destination} is placed and pending confirmation.',
              type: 'booking',
            ).catchError((e) => debugPrint('Note: Error inserting notification: $e'));
          }
          _triggerPushNotifications(bookingId, s.destination);
          final s12 = state.value ?? BookingState();
          state = AsyncValue.data(s12.copyWith(
            isLoading: false,
            bookingStatus: BookingResponse(
              success: true,
              message: 'Payment successful via Wallet',
              bookingId: bookingId,
            ),
          ));
        } catch (e) {
          final s13 = state.value ?? BookingState();
          state = AsyncValue.data(s13.copyWith(
            isLoading: false,
            error: e.toString().replaceAll('Exception: ', ''),
          ));
        }
      } else {
        // No payment gateway → direct confirm
        ref.read(bookingRepositoryProvider).addRecentDestination(s.destination);
        ref.invalidate(bookingsStreamProvider);
        final bookingId = response.bookingId ?? '';
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null && bookingId.isNotEmpty) {
          ref.read(notificationRepositoryProvider).insert(
            userId: userId,
            title: 'Booking Placed Successfully!',
            body: 'Your booking #${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId} to ${s.destination} is placed and pending confirmation.',
            type: 'booking',
          ).catchError((e) => debugPrint('Note: Error inserting notification: $e'));
          _triggerPushNotifications(bookingId, s.destination);
        }
        final s11 = state.value ?? BookingState();
        state = AsyncValue.data(s11.copyWith(
          isLoading: false,
          bookingStatus: response,
        ));
      }
    } catch (e) {
      final s12 = state.value ?? BookingState();
      state = AsyncValue.data(s12.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _triggerPushNotifications(String bookingId, String destination) async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return;

    final shortId = bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId;
    final currentUserEmail = user?.email ?? 'Unknown User';

    // Fetch user's full name from profiles
    String senderName = currentUserEmail;
    try {
      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (userProfile != null && userProfile['full_name'] != null) {
        senderName = userProfile['full_name'] as String;
      }
    } catch (_) {}

    // 1. Send push to passenger
    PushNotificationService().sendPushNotification(
      recipientUserId: userId,
      title: 'Booking Placed Successfully! 🚗',
      body: 'Your ride request #$shortId to $destination is pending chauffeur assignment.',
    ).catchError((e) => debugPrint('Note: Error dispatching passenger push: $e'));

    // 2. Fetch admins and send push to all of them
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', 'admin');

      if (response != null && response is List) {
        debugPrint('📣 Found ${response.length} admin(s) in profiles. Dispatching admin alerts...');
        for (final row in response) {
          final adminId = row['id'] as String?;
          if (adminId != null) {
            debugPrint('📣 Dispatching admin push notification to Admin User ID: $adminId');
            PushNotificationService().sendPushNotification(
              recipientUserId: adminId,
              title: 'New Booking Request Received! 🔔',
              body: 'Ride #$shortId to $destination has been booked by $senderName ($currentUserEmail) and is waiting for your confirmation.',
            ).catchError((e) => debugPrint('❌ Error dispatching admin push: $e'));
          }
        }
      } else {
        debugPrint('⚠️ No admin profiles found to send push notifications.');
      }
    } catch (e) {
      debugPrint('❌ Could not query admin profiles for push notification: $e');
    }
  }

  void cancelPayment() {
    final s = state.value ?? BookingState();
    state = AsyncValue.data(s.copyWith(requiresPayment: false, checkoutUrl: null));
  }
}

final bookingViewModelProvider = AsyncNotifierProvider<BookingViewModel, BookingState>(() {
  return BookingViewModel();
});
