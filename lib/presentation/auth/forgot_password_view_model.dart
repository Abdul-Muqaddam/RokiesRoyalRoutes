import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

enum ForgotPasswordStep { email, otp, newPassword, success }

class ForgotPasswordViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state
  }

  ForgotPasswordStep _currentStep = ForgotPasswordStep.email;
  ForgotPasswordStep get currentStep => _currentStep;

  String _email = '';
  String get email => _email;

  String _otp = '';
  String get otp => _otp;

  String _newPassword = '';
  String get newPassword => _newPassword;

  String _confirmPassword = '';
  String get confirmPassword => _confirmPassword;

  String? _error;
  String? get error => _error;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void onEmailChanged(String value) {
    _email = value;
    _error = null;
    state = const AsyncValue.data(null);
  }

  void onOtpChanged(String value) {
    _otp = value;
    _error = null;
    state = const AsyncValue.data(null);
  }

  void onNewPasswordChanged(String value) {
    _newPassword = value;
    _error = null;
    state = const AsyncValue.data(null);
  }

  void onConfirmPasswordChanged(String value) {
    _confirmPassword = value;
    _error = null;
    state = const AsyncValue.data(null);
  }

  Future<void> requestOtp() async {
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

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.forgotPassword(_email);
      
      if (response.success) {
        _currentStep = ForgotPasswordStep.otp;
        _successMessage = "A verification code has been sent to your email.";
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

  Future<void> verifyOtp() async {
    if (_otp.isEmpty) {
      _error = "Please enter the verification code";
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    _error = null;

    // TODO: Temporary bypass for UI testing
    await Future.delayed(const Duration(milliseconds: 500)); // Small fake delay
    _currentStep = ForgotPasswordStep.newPassword;
    _successMessage = null; // Clear success message so it doesn't show on next screen
    state = const AsyncValue.data(null);

    /* Original Implementation
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.verifyResetOtp(_email, _otp);
      
      if (response.success) {
        _currentStep = ForgotPasswordStep.newPassword;
        _successMessage = "Code verified. Please set your new password.";
        state = const AsyncValue.data(null);
      } else {
        _error = response.message;
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      _error = e.toString();
      state = const AsyncValue.data(null);
    }
    */
  }

  Future<void> resetPassword() async {
    if (_newPassword.length < 6) {
      _error = "Password must be at least 6 characters";
      state = const AsyncValue.data(null);
      return;
    }

    if (_newPassword != _confirmPassword) {
      _error = "Passwords do not match";
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    _error = null;

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.resetPassword(_newPassword);
      
      if (response.success) {
        _currentStep = ForgotPasswordStep.success;
        _successMessage = "Your password has been reset successfully.";
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
    _otp = '';
    _newPassword = '';
    _confirmPassword = '';
    _error = null;
    _successMessage = null;
    _currentStep = ForgotPasswordStep.email;
    state = const AsyncValue.data(null);
  }
  
  void goToStep(ForgotPasswordStep step) {
    _currentStep = step;
    _error = null;
    state = const AsyncValue.data(null);
  }
}

final forgotPasswordViewModelProvider = AsyncNotifierProvider<ForgotPasswordViewModel, void>(() {
  return ForgotPasswordViewModel();
});
