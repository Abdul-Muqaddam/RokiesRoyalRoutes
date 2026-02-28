import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api_service.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/auth_repository_impl.dart';

abstract class UserRepository {
  Future<UserProfileResponse> getUserProfile();
}

class UserRepositoryImpl implements UserRepository {
  final ApiService _apiService;

  UserRepositoryImpl(this._apiService);

  @override
  Future<UserProfileResponse> getUserProfile() async {
    return _apiService.getUserProfile();
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(apiServiceProvider));
});
