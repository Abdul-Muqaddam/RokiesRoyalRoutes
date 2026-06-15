import '../../data/models/auth_models.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String username, String password);
  Future<AuthResponse> adminLogin(String username, String password);
  Future<AuthResponse> driverLogin(String username, String password);
  Future<AuthResponse> register(RegisterRequest request);
  Future<AuthResponse> forgotPassword(String email);
  Future<AuthResponse> verifyResetOtp(String email, String otp);
  Future<AuthResponse> resetPassword(String newPassword);
  Future<void> logout();
  bool isLoggedIn();
}
