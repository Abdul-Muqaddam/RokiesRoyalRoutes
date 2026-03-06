import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../local/preferences_manager.dart';
import '../models/auth_models.dart';
import '../remote/api_service.dart';
import '../../domain/repositories/auth_repository.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(apiServiceProvider),
    ref.watch(preferencesManagerProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final PreferencesManager _preferencesManager;

  AuthRepositoryImpl(this._apiService, this._preferencesManager);

  @override
  Future<AuthResponse> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final response = await _apiService.login(request);
    
    if (response.success && response.token.isNotEmpty) {
      await _preferencesManager.saveToken(response.token);
    }
    return response;
  }

  @override
  Future<AuthResponse> adminLogin(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final response = await _apiService.adminLogin(request);
    
    // Only save the token if it's necessary for the admin UI session
    if (response.success && response.token.isNotEmpty) {
      await _preferencesManager.saveToken(response.token);
    }
    return response;
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _apiService.register(request);
    
    if (response.success && response.token.isNotEmpty) {
      await _preferencesManager.saveToken(response.token);
    }
    return response;
  }

  @override
  Future<AuthResponse> forgotPassword(String email) async {
    return _apiService.forgotPassword(ForgotPasswordRequest(email: email));
  }

  @override
  Future<void> logout() async {
    await _preferencesManager.clearToken();
  }

  @override
  bool isLoggedIn() {
    final token = _preferencesManager.getToken();
    return token != null && token.isNotEmpty;
  }
}
