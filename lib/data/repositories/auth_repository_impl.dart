import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import '../local/preferences_manager.dart';
import '../models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/services/push_notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(preferencesManagerProvider),
  );
});

final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AuthRepositoryImpl implements AuthRepository {
  final PreferencesManager _preferencesManager;
  final _supabase = Supabase.instance.client;

  AuthRepositoryImpl(this._preferencesManager);

  @override
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: username,
        password: password,
      );
      if (response.session != null && response.user != null) {
        final userMeta = response.user!.userMetadata ?? {};
        final appMeta = response.user!.appMetadata ?? {};
        final role = userMeta['role']?.toString() ?? appMeta['role']?.toString() ?? '';

        // Reject drivers trying to log in as passengers
        if (role == 'driver') {
          await _supabase.auth.signOut();
          return AuthResponse(success: false, message: 'These credentials belong to a driver account. Please select the Driver role to log in.', token: '');
        }

        await _preferencesManager.saveToken(response.session!.accessToken);
        await PushNotificationService().onUserLogin();
        return AuthResponse(success: true, message: 'Login successful', token: response.session!.accessToken);
      }
      return AuthResponse(success: false, message: 'Invalid credentials', token: '');
    } catch (e) {
      return AuthResponse(success: false, message: e.toString(), token: '');
    }
  }

  @override
  Future<AuthResponse> adminLogin(String username, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: username,
        password: password,
      );
      
      if (response.session != null && response.user != null) {
        final user = response.user!;
        bool isAdmin = false;
        
        // Check both user_metadata and app_metadata, as well as if 'admin' is in the email or username
        final userMeta = user.userMetadata ?? {};
        final appMeta = user.appMetadata ?? {};
        
        if (userMeta['role'] == 'admin' || userMeta['is_admin'] == true ||
            appMeta['role'] == 'admin' || appMeta['is_admin'] == true ||
            user.email?.toLowerCase().contains('admin') == true ||
            userMeta['username']?.toString().toLowerCase() == 'admin' ||
            userMeta['full_name']?.toString().toLowerCase().contains('admin') == true) {
          isAdmin = true;
        }
        
        // If they are an admin, proceed
        if (isAdmin) {
          await _preferencesManager.saveAdminToken(response.session!.accessToken);
          await PushNotificationService().onUserLogin();
          return AuthResponse(success: true, message: 'Admin login successful', token: response.session!.accessToken);
        } else {
          // If they aren't an admin, sign out and reject
          await _supabase.auth.signOut();
          return AuthResponse(success: false, message: 'Access denied: You do not have admin privileges.', token: '');
        }
      }
      return AuthResponse(success: false, message: 'Invalid credentials', token: '');
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        return AuthResponse(success: false, message: 'Invalid credentials', token: '');
      }
      return AuthResponse(success: false, message: e.toString(), token: '');
    }
  }

  @override
  Future<AuthResponse> driverLogin(String username, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: username,
        password: password,
      );
      
      if (response.session != null && response.user != null) {
        final user = response.user!;
        bool isDriver = false;
        
        final userMeta = user.userMetadata ?? {};
        final appMeta = user.appMetadata ?? {};
        
        if (userMeta['role'] == 'driver' || appMeta['role'] == 'driver' ||
            user.email?.toLowerCase().contains('driver') == true) {
          isDriver = true;
        }
        
        if (isDriver) {
          await _preferencesManager.saveDriverToken(response.session!.accessToken);
          await PushNotificationService().onUserLogin();
          return AuthResponse(success: true, message: 'Driver login successful', token: response.session!.accessToken);
        } else {
          await _supabase.auth.signOut();
          return AuthResponse(success: false, message: 'Access denied: You do not have driver privileges.', token: '');
        }
      }
      return AuthResponse(success: false, message: 'Invalid credentials', token: '');
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        return AuthResponse(success: false, message: 'Invalid credentials', token: '');
      }
      return AuthResponse(success: false, message: e.toString(), token: '');
    }
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _supabase.auth.signUp(
        email: request.email,
        password: request.password,
        data: {
          'full_name': request.name,
          'username': request.username,
          'role': request.role,
        },
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

      if (response.user != null) {
        // Attempt client-side sync fallback for the profiles table role field
        try {
          await _supabase
              .from('profiles')
              .update({'role': request.role})
              .eq('id', response.user!.id);
          print('DEBUG: Successfully set profile role to ${request.role} for user ${response.user!.id}');
        } catch (e) {
          print('DEBUG: Profile table role update fallback failed (expected if RLS limits it or email verification is active): $e');
        }
      }

      if (response.session != null) {
        await _preferencesManager.saveToken(response.session!.accessToken);
        return AuthResponse(success: true, message: 'Registration successful', token: response.session!.accessToken);
      } else if (response.user != null) {
        return AuthResponse(success: true, message: 'Registration successful. Verification required.', token: '');
      }
      return AuthResponse(success: false, message: 'Registration failed', token: '');
    } catch (e) {
      return AuthResponse(success: false, message: e.toString(), token: '');
    }
  }

  @override
  Future<AuthResponse> forgotPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResponse(success: true, message: 'Password reset email sent', token: '');
    } catch (e) {
      return AuthResponse(success: false, message: e.toString(), token: '');
    }
  }

  @override
  Future<AuthResponse> verifyResetOtp(String email, String otp) async {
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: otp,
        email: email,
      );
      return AuthResponse(success: true, message: 'OTP verified successfully', token: '');
    } on AuthException catch (e) {
      String msg = e.message;
      if (e.code == 'otp_expired' || msg.toLowerCase().contains('expired') || msg.toLowerCase().contains('invalid')) {
        msg = 'The verification code is incorrect or has expired.';
      }
      return AuthResponse(success: false, message: msg, token: '');
    } catch (e) {
      return AuthResponse(success: false, message: 'An unexpected error occurred. Please try again.', token: '');
    }
  }

  @override
  Future<AuthResponse> resetPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      return AuthResponse(success: true, message: 'Password reset successfully', token: '');
    } catch (e) {
      return AuthResponse(success: false, message: e.toString(), token: '');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await PushNotificationService().onUserLogout();
      await _supabase.auth.signOut();
    } catch (_) {}
    await _preferencesManager.removeToken();
    await _preferencesManager.removeAdminToken();
    await _preferencesManager.removeDriverToken();
  }


  @override
  bool isLoggedIn() {
    return _supabase.auth.currentSession != null;
  }
}
