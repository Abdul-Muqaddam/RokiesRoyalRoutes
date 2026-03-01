import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/user_repository_impl.dart';

part 'personal_information_view_model.g.dart';

@riverpod
class PersonalInformationViewModel extends _$PersonalInformationViewModel {
  @override
  FutureOr<void> build() {}

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? name,
    String? nickname,
    String? phone,
    String? website,
    String? bio,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      final request = UpdateProfileRequest(
        firstName: firstName,
        lastName: lastName,
        name: name,
        nickname: nickname,
        phone: phone,
        website: website,
        bio: bio,
      );
      final response = await repository.updateProfile(request);
      if (!response.success) {
        throw Exception(response.message);
      }
      ref.invalidate(userProfileProvider);
    });
  }
}
