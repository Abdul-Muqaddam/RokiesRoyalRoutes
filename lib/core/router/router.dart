import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/splash_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/personal_information_screen.dart';
import '../../presentation/profile/change_password_screen.dart';
import '../../presentation/booking/booking_screen.dart';
import '../../presentation/booking/booking_success_screen.dart';
import '../../presentation/booking/invoice_screen.dart';
import '../../presentation/auth/admin_login_screen.dart';
import '../../presentation/customization/customization_screen.dart';
import '../../presentation/home/home_screen_customization_screen.dart';
import '../../presentation/profile/profile_customization_screen.dart';
import '../../presentation/booking/booking_step_customization_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/personal-info',
        builder: (context, state) => const PersonalInformationScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: '/booking-success',
        builder: (context, state) => const BookingSuccessScreen(),
      ),
      GoRoute(
        path: '/invoice',
        builder: (context, state) => const InvoiceScreen(),
      ),
      GoRoute(
        path: '/admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/customization',
        builder: (context, state) => const CustomizationScreen(),
      ),
      GoRoute(
        path: '/home-customization',
        builder: (context, state) => const HomeScreenCustomizationScreen(),
      ),
      GoRoute(
        path: '/profile-customization',
        builder: (context, state) => const ProfileCustomizationScreen(),
      ),
      GoRoute(
        path: '/booking-step-1-customization',
        builder: (context, state) => const BookingStepCustomizationScreen(stepIndex: 1),
      ),
      GoRoute(
        path: '/booking-step-2-customization',
        builder: (context, state) => const BookingStepCustomizationScreen(stepIndex: 2),
      ),
      GoRoute(
        path: '/booking-step-3-customization',
        builder: (context, state) => const BookingStepCustomizationScreen(stepIndex: 3),
      ),
      GoRoute(
        path: '/booking-step-4-customization',
        builder: (context, state) => const BookingStepCustomizationScreen(stepIndex: 4),
      ),
    ],
  );
});
