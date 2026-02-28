import '../models/user_models.dart';
import '../remote/api_service.dart';
import 'auth_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository_impl.g.dart';

abstract class UserRepository {
  Future<UserProfileResponse> getUserProfile();
  Future<ChangePasswordResponse> changePassword(ChangePasswordRequest request);
}

class UserRepositoryImpl implements UserRepository {
  final ApiService _apiService;

  UserRepositoryImpl(this._apiService);

  @override
  Future<UserProfileResponse> getUserProfile() async {
    return _apiService.getUserProfile();
  }

  @override
  Future<ChangePasswordResponse> changePassword(ChangePasswordRequest request) async {
    return _apiService.changePassword(request);
  }
}

@riverpod
UserRepository userRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserRepositoryImpl(apiService);
}

@riverpod
Future<UserDto> userProfile(Ref ref) async {
  final repository = ref.watch(userRepositoryProvider);
  final response = await repository.getUserProfile();
  if (response.success && response.user != null) {
    return response.user!;
  } else {
    throw Exception(response.message);
  }
}
