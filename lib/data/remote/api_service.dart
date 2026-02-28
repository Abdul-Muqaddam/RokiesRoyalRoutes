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

  Future<UserProfileResponse> getUserProfile() async {
    final response = await _dio.get('user/profile');
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
      if (data is List) {
        return data.map((e) => VehicleDto.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map) {
        final list = data['vehicles'] ?? data['data'] ?? [];
        if (list is List) {
          return list.map((e) => VehicleDto.fromJson(e as Map<String, dynamic>)).toList();
        }
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
}
