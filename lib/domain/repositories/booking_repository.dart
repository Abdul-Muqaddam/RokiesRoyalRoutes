import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/models/booking_models.dart';
import '../../data/models/user_models.dart';
import '../../data/services/stripe_service.dart';
import '../../data/services/paypal_service.dart';

abstract class BookingRepository {
  Future<BookingResponse> createBooking(BookingRequest request);
  Future<DistanceMatrixResponse> getDistanceMatrix(String origin, String destination);
  Future<List<PaymentGateway>> getPaymentGateways();
  Future<List<LocationItem>> getRecentDestinations();
  Future<void> addRecentDestination(String address);
  Future<List<Trip>> getUpcomingTrips();
  Future<List<Trip>> getAllTrips();
  Future<SavedLocationsResponse> getSavedLocations();
  Stream<List<Trip>> watchBookings();
  Future<bool> assignDriver(String bookingId, String driverId, {String? status});
  Future<bool> updateBookingStatus(String bookingId, String status);
  Future<List<UserDto>> getDrivers();
  Future<AutocompleteResponse> getAutocompleteSuggestions(String input, String apiKey);
  Future<List<LatLng>> getDirections(LatLng origin, LatLng destination);
  Future<UserProfileResponse> updateSavedLocations(UpdateLocationsRequest request);
}

class BookingRepositoryImpl implements BookingRepository {
  final _supabase = Supabase.instance.client;
  final _dio = Dio();

  BookingRepositoryImpl();

  @override
  Future<BookingResponse> createBooking(BookingRequest request) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return BookingResponse(success: false, message: 'Not logged in');

      final response = await _supabase.from('bookings').insert({
        'user_id': user.id,
        'vehicle_id': request.vehicleId.toString(),
        'pickup_location': request.pickupLocation,
        'dropoff_location': request.dropoffLocation,
        'pickup_date': request.pickupDate,
        'pickup_time': request.pickupTime,
        'passengers': request.passengers,
        'luggage': request.luggage,
        'payment_gateway': request.paymentGateway,
        'total_price': request.totalPrice,
        'currency': request.currency ?? 'CAD',
        'status': 'pending',
        'customer_info': request.customerInfo.toJson(),
      }).select().single();

      return BookingResponse(
        success: true, 
        message: 'Booking created successfully', 
        bookingId: response['id'].toString(),
      );
    } catch (e) {
      return BookingResponse(success: false, message: e.toString());
    }
  }

  @override
  Future<DistanceMatrixResponse> getDistanceMatrix(String origin, String destination) async {
    const googleApiKey = "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8"; 
    final url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=$origin&destinations=$destination&mode=driving&units=metric&key=$googleApiKey";
    
    try {
      final response = await _dio.get(url);
      return DistanceMatrixResponse.fromJson(response.data);
    } catch (e) {
      return DistanceMatrixResponse(rows: [], status: 'ERROR');
    }
  }

  @override
  Future<List<PaymentGateway>> getPaymentGateways() async {
    return [
      PaymentGateway(id: 'stripe', title: 'Stripe (Credit Card)', description: 'Pay securely with your credit card', enabled: true),
      PaymentGateway(id: 'paypal', title: 'PayPal', description: 'Pay with your PayPal account', enabled: true),
      PaymentGateway(id: 'wallet', title: 'My Wallet', description: 'Pay using your app wallet balance', enabled: true),
      PaymentGateway(id: 'cash', title: 'Cash', description: 'Pay with cash upon arrival', enabled: true),
    ];
  }

  @override
  Future<List<UserDto>> getDrivers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'driver');
      
      final List<dynamic> data = response as List;
      return data.map<UserDto>((item) {
        return UserDto(
          id: 0,
          name: item['full_name']?.toString() ?? item['username']?.toString() ?? 'Unknown Driver',
          email: item['email']?.toString() ?? '',
          phone: item['phone']?.toString() ?? '',
          avatarUrl: item['avatar_url']?.toString() ?? '',
          role: 'driver',
          uid: item['id']?.toString(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<LocationItem>> getRecentDestinations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('recent_destinations')
          .select('address')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);

      final List<dynamic> data = response as List;
      final locations = data
          .map((e) => e['address'] as String)
          .toSet() // Remove duplicates
          .map((e) => LocationItem(name: 'Recent', address: e))
          .toList();

      return locations;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addRecentDestination(String address) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if already exists to update timestamp instead of duplicate
      final existing = await _supabase
          .from('recent_destinations')
          .select()
          .eq('user_id', user.id)
          .eq('address', address)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('recent_destinations')
            .update({'created_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
      } else {
        await _supabase.from('recent_destinations').insert({
          'user_id': user.id,
          'address': address,
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<List<Trip>> getUpcomingTrips() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    return trips.where((trip) {
      if (trip.pickupDate == null || trip.pickupTime == null) return false;
      try {
        final tripDate = DateTime.parse('${trip.pickupDate} ${trip.pickupTime}');
        return tripDate.isAfter(now) || tripDate.isAtSameMomentAs(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Future<List<Trip>> getAllTrips() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response.map((data) => _mapJsonToTrip(data)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<Trip>> watchBookings() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }
    yield* _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => _mapJsonToTrip(json)).toList());
  }

  Trip _mapJsonToTrip(Map<String, dynamic> data) {
    return Trip(
      id: data['id'].toString(),
      title: '${data['pickup_location']} to ${data['dropoff_location']}',
      dateTime: '${data['pickup_date']} at ${data['pickup_time']}',
      status: _mapStatus(data['status'] ?? 'pending'),
      vehicleType: 'Executive Sedan', 
      pickupDate: data['pickup_date'],
      pickupTime: data['pickup_time'],
      dropoffLocation: data['dropoff_location'],
      pickupLocation: data['pickup_location'],
      price: '${data['currency'] ?? 'CAD'} ${data['total_price'] ?? '0.00'}',
      reference: '#${data['id'].toString().substring(0, 8)}',
      userId: data['user_id']?.toString(),
      driverId: data['driver_id']?.toString(),
      paymentGateway: data['payment_gateway']?.toString(),
      vehicleId: data['vehicle_id']?.toString(),
    );
  }

  TripStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return TripStatus.confirmed;
      case 'cancelled': return TripStatus.cancelled;
      case 'in_progress': return TripStatus.inProgress;
      case 'arrived': return TripStatus.arrived;
      case 'past':
      case 'completed': return TripStatus.past;
      default: return TripStatus.pending;
    }
  }

  @override
  Future<SavedLocationsResponse> getSavedLocations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return SavedLocationsResponse(custom: []);

      final response = await _supabase
          .from('saved_locations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List;
      String? home;
      String? work;
      final List<CustomPlace> custom = [];

      for (final item in data) {
        final type = item['type']?.toString().toLowerCase();
        final name = item['name']?.toString() ?? '';
        final address = item['address']?.toString() ?? '';
        if (type == 'home' || name.toLowerCase() == 'home') home = address;
        else if (type == 'work' || name.toLowerCase() == 'work') work = address;
        else custom.add(CustomPlace(name: name, address: address));
      }
      return SavedLocationsResponse(home: home, work: work, custom: custom);
    } catch (e) {
      return SavedLocationsResponse(custom: []);
    }
  }

  @override
  Future<bool> assignDriver(String bookingId, String driverId, {String? status}) async {
    try {
      final Map<String, dynamic> updateData = {'driver_id': driverId};
      if (status != null) updateData['status'] = status;
      final response = await _supabase.from('bookings').update(updateData).eq('id', bookingId).select();
      return response != null && (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await _supabase.from('bookings').update({'status': status}).eq('id', bookingId).select();
      return response != null && (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AutocompleteResponse> getAutocompleteSuggestions(String input, String apiKey) async {
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey";
    try {
      final response = await _dio.get(url);
      return AutocompleteResponse.fromJson(response.data);
    } catch (e) {
      return AutocompleteResponse(predictions: [], status: 'ERROR');
    }
  }

  @override
  Future<List<LatLng>> getDirections(LatLng origin, LatLng destination) async {
    const googleApiKey = "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8";
    final url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey";
    try {
      final response = await _dio.get(url);
      if (response.data['status'] == 'OK') {
        final String encodedPolyline = response.data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(encodedPolyline);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  @override
  Future<UserProfileResponse> updateSavedLocations(UpdateLocationsRequest request) async {
    return UserProfileResponse(success: true, message: 'Updated');
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) => BookingRepositoryImpl());

final bookingsStreamProvider = StreamProvider.autoDispose<List<Trip>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.watchBookings();
});

final recentDestinationsProvider = FutureProvider.autoDispose<List<LocationItem>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getRecentDestinations();
});

final paymentGatewaysProvider = FutureProvider.autoDispose<List<PaymentGateway>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getPaymentGateways();
});

