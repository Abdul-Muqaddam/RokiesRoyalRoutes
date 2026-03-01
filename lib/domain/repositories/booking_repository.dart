import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/models/booking_models.dart';
import '../../data/models/user_models.dart';

abstract class BookingRepository {
  Future<BookingResponse> createBooking(BookingRequest request);
  Future<DistanceMatrixResponse> getDistanceMatrix(String origin, String destination);
  Future<List<PaymentGateway>> getPaymentGateways();
  Future<List<LocationItem>> getRecentDestinations();
  Future<void> addRecentDestination(String address);
  Future<List<Trip>> getUpcomingTrips();
  Future<List<Trip>> getAllTrips();
  Future<SavedLocationsResponse> getSavedLocations();
  Future<StripeSessionResponse> createStripeSession(int bookingId);
  Future<StripeVerifyResponse> verifyStripeSession(String sessionId, int bookingId);
  Future<PayPalOrderResponse> createPayPalOrder(int bookingId);
  Future<PayPalExecuteResponse> executePayPalPayment(String orderId, int bookingId);
}

class BookingRepositoryImpl implements BookingRepository {
  final ApiService _apiService;

  BookingRepositoryImpl(this._apiService);

  @override
  Future<BookingResponse> createBooking(BookingRequest request) => _apiService.createBooking(request);

  @override
  Future<DistanceMatrixResponse> getDistanceMatrix(String origin, String destination) {
    // We'll use the same key as for autocomplete for now
    const googleApiKey = "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8"; 
    return _apiService.getDistanceMatrix(origin, destination, googleApiKey);
  }

  @override
  Future<List<PaymentGateway>> getPaymentGateways() => _apiService.getPaymentGateways();

  @override
  Future<List<LocationItem>> getRecentDestinations() => _apiService.getRecentDestinations();

  @override
  Future<void> addRecentDestination(String address) => _apiService.addRecentDestination(address);

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
    final response = await _apiService.getUserBookings();
    
    final trips = response.map((dto) {
      final status = _mapStatus(dto.status ?? 'pending');
      
      return Trip(
        id: dto.id.toString(),
        title: _cleanTitle(dto.title ?? ''),
        dateTime: _formatDateTime(dto),
        status: status,
        vehicleType: 'Executive Sedan',
        pickupDate: dto.pickupDate,
        pickupTime: dto.pickupTime,
        dropoffLocation: dto.dropoffLocation,
        pickupLocation: dto.pickupLocation,
        price: '${dto.currency ?? 'CAD'} ${dto.totalPrice ?? '0.00'}',
        reference: '#${dto.id}',
      );
    }).toList();

    return trips..sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
  }

  TripStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'publish':
      case 'confirmed':
        return TripStatus.confirmed;
      case 'cancelled':
        return TripStatus.cancelled;
      case 'past':
      case 'completed':
        return TripStatus.past;
      default:
        return TripStatus.pending;
    }
  }

  String _cleanTitle(String title) {
    final regex = RegExp(r' - \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');
    return title.replaceFirst(regex, '');
  }

  String _formatDateTime(UserBookingResponse dto) {
    if (dto.pickupDate == null || dto.pickupTime == null) return 'Unknown';
    return '${dto.pickupDate} at ${dto.pickupTime}';
  }

  @override
  Future<SavedLocationsResponse> getSavedLocations() => _apiService.getSavedLocations();

  @override
  Future<StripeSessionResponse> createStripeSession(int bookingId) => _apiService.createStripeSession(bookingId);

  @override
  Future<StripeVerifyResponse> verifyStripeSession(String sessionId, int bookingId) => _apiService.verifyStripeSession(sessionId, bookingId);

  @override
  Future<PayPalOrderResponse> createPayPalOrder(int bookingId) => _apiService.createPayPalOrder(bookingId);

  @override
  Future<PayPalExecuteResponse> executePayPalPayment(String orderId, int bookingId) => _apiService.executePayPalPayment(orderId, bookingId);
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(ref.watch(apiServiceProvider));
});
