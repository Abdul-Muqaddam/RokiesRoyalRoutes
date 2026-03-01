import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import '../models/user_models.dart';
import '../models/vehicle_models.dart';
import '../models/booking_models.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post('auth/login', data: request.toJson());
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post('auth/register', data: request.toJson());
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> forgotPassword(ForgotPasswordRequest request) async {
    final response = await _dio.post('auth/forgot-password', data: request.toJson());
    return AuthResponse.fromJson(response.data);
  }

  Future<UserProfileResponse> getUserProfile() async {
    final response = await _dio.get('user/profile');
    return UserProfileResponse.fromJson(response.data);
  }

  Future<UserProfileResponse> updateProfile(UpdateProfileRequest request) async {
    final response = await _dio.post('user/profile', data: request.toJson());
    return UserProfileResponse.fromJson(response.data);
  }

  Future<ChangePasswordResponse> changePassword(ChangePasswordRequest request) async {
    final response = await _dio.post('user/change-password', data: request.toJson());
    return ChangePasswordResponse.fromJson(response.data);
  }

  Future<List<VehicleDto>> getVehicles() async {
    try {
      final response = await _dio.get('vehicles');
      final data = response.data;
      List<dynamic> listData = [];
      if (data is List) {
        listData = data;
      } else if (data is Map) {
        listData = data['vehicles'] ?? data['data'] ?? [];
      }
      
      if (listData is List) {
        return listData.map((e) {
          if (e is Map<String, dynamic>) return VehicleDto.fromJson(e);
          return null;
        }).whereType<VehicleDto>().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<UserBookingResponse>> getUserBookings() async {
    final response = await _dio.get('user/bookings');
    return UserBookingsWrapperDto.fromJson(response.data).bookings;
  }

  Future<SavedLocationsResponse> getSavedLocations() async {
    final response = await _dio.get('user/saved-locations');
    return SavedLocationsResponse.fromJson(response.data);
  }

  Future<UserProfileResponse> updateSavedLocations(UpdateLocationsRequest request) async {
    final response = await _dio.post('user/saved-locations', data: request.toJson());
    return UserProfileResponse.fromJson(response.data);
  }

  Future<AutocompleteResponse> getAutocompleteSuggestions(String input, String apiKey) async {
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey";
    final response = await _dio.get(url);
    return AutocompleteResponse.fromJson(response.data);
  }

  Future<BookingResponse> createBooking(BookingRequest request) async {
    final response = await _dio.post('create-booking', data: request.toJson());
    return BookingResponse.fromJson(response.data);
  }

  Future<DistanceMatrixResponse> getDistanceMatrix(String origin, String destination, String apiKey) async {
    final url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=$origin&destinations=$destination&mode=driving&units=metric&key=$apiKey";
    final response = await _dio.get(url);
    return DistanceMatrixResponse.fromJson(response.data);
  }

  Future<List<PaymentGateway>> getPaymentGateways() async {
    final response = await _dio.get('payment-gateways');
    final data = response.data;
    List<dynamic> listData = [];
    if (data is List) {
      listData = data;
    } else if (data is Map) {
      listData = data['data'] ?? data['gateways'] ?? [];
    }

    if (listData is List) {
      return listData.map((e) {
        if (e is Map<String, dynamic>) return PaymentGateway.fromJson(e);
        return null;
      }).whereType<PaymentGateway>().toList();
    }
    return [];
  }

  Future<void> addRecentDestination(String address) async {
    await _dio.post('user/recent-destinations', data: {'address': address});
  }

  Future<List<LocationItem>> getRecentDestinations() async {
    final response = await _dio.get('user/recent-destinations');
    final data = response.data;
    List<dynamic> listData = [];
    if (data is List) {
      listData = data;
    } else if (data is Map) {
      listData = data['data'] ?? data['recent'] ?? [];
    }

    if (listData is List) {
      return listData.map((e) {
        if (e is Map<String, dynamic>) return LocationItem.fromJson(e);
        if (e is String) return LocationItem(name: 'Recent', address: e);
        return null;
      }).whereType<LocationItem>().toList();
    }
    return [];
  }

  Future<StripeSessionResponse> createStripeSession(int bookingId) async {
    final response = await _dio.post('stripe/create-session', queryParameters: {'booking_id': bookingId});
    return StripeSessionResponse.fromJson(response.data);
  }

  Future<StripeVerifyResponse> verifyStripeSession(String sessionId, int bookingId) async {
    final response = await _dio.post('stripe/verify-session', queryParameters: {
      'session_id': sessionId,
      'booking_id': bookingId,
    });
    return StripeVerifyResponse.fromJson(response.data);
  }

  Future<PayPalOrderResponse> createPayPalOrder(int bookingId) async {
    final response = await _dio.post('paypal/create-order', data: PayPalOrderRequest(bookingId).toJson());
    return PayPalOrderResponse.fromJson(response.data);
  }

  Future<PayPalExecuteResponse> executePayPalPayment(String orderId, int bookingId) async {
    final response = await _dio.post('paypal/execute-payment', data: PayPalExecuteRequest(orderId, bookingId).toJson());
    return PayPalExecuteResponse.fromJson(response.data);
  }
}
