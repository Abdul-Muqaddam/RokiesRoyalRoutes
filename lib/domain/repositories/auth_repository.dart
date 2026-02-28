import '../../data/models/auth_models.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String username, String password);
  Future<AuthResponse> register(RegisterRequest request);
  Future<void> logout();
  bool isLoggedIn();
}
