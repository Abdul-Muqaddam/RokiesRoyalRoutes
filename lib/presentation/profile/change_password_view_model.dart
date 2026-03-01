import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/user_repository_impl.dart';

part 'change_password_view_model.g.dart';

@riverpod
class ChangePasswordViewModel extends _$ChangePasswordViewModel {
  @override
  FutureOr<void> build() {}

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      final request = ChangePasswordRequest(
        oldPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );
      final response = await repository.changePassword(request);
      if (!response.success) {
        throw Exception(response.message);
      }
    });
  }
}
