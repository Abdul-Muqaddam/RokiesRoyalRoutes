import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

class ForgotPasswordViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle
  }

  String _email = '';
  String get email => _email;

  String? _error;
  String? get error => _error;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void onEmailChanged(String value) {
    _email = value;
    _error = null;
    state = const AsyncValue.data(null);
  }

  Future<void> forgotPassword() async {
    if (_email.isEmpty) {
      _error = "Email address cannot be empty";
      state = const AsyncValue.data(null);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_email)) {
      _error = "Please enter a valid email address";
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    _error = null;
    _successMessage = null;

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.forgotPassword(_email);
      
      if (response.success) {
        _successMessage = "A password reset email has been sent to your inbox.";
        state = const AsyncValue.data(null);
      } else {
        _error = response.message;
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      _error = e.toString();
      state = const AsyncValue.data(null);
    }
  }

  void resetState() {
    _email = '';
    _error = null;
    _successMessage = null;
    state = const AsyncValue.data(null);
  }
}

final forgotPasswordViewModelProvider = AsyncNotifierProvider<ForgotPasswordViewModel, void>(() {
  return ForgotPasswordViewModel();
});
