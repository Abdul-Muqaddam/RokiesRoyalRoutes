import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/splash_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/home/complain_screen.dart';
import '../../presentation/home/referral_screen.dart';
import '../../presentation/home/about_us_screen.dart';
import '../../presentation/notification/notification_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/personal_information_screen.dart';
import '../../presentation/profile/change_password_screen.dart';
import '../../presentation/profile/saved_locations_screen.dart';
import '../../presentation/booking/booking_screen.dart';
import '../../presentation/booking/booking_success_screen.dart';
import '../../presentation/booking/invoice_screen.dart';
import '../../presentation/booking/available_cars_screen.dart';
import '../../presentation/booking/car_details_screen.dart';
import '../../presentation/auth/admin_login_screen.dart';
import '../../presentation/customization/customization_screen.dart';
import '../../presentation/home/home_screen_customization_screen.dart';
import '../../presentation/profile/profile_customization_screen.dart';
import '../../presentation/booking/booking_step_customization_screen.dart';
import '../../presentation/trips/trips_screen.dart';
import '../../presentation/trips/trip_details_screen.dart';
import '../../data/models/booking_models.dart';
import '../../data/models/vehicle_models.dart';
import '../../data/models/user_models.dart';
import '../../presentation/screens/vehicles_screen.dart';
import '../../presentation/admin/track_driver_screen.dart';
import '../../presentation/admin/admin_panel_screen.dart';
import '../../presentation/admin/assign_booking_screen.dart';
import '../../presentation/driver/driver_home_screen.dart';
import '../../presentation/driver/driver_trip_route_screen.dart';
import '../../presentation/chat/chat_screen.dart';
import '../../presentation/auth/welcome_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/settings/language_screen.dart';
import '../../presentation/settings/privacy_policy_screen.dart';
import '../../presentation/settings/contact_us_screen.dart';
import '../../presentation/settings/delete_account_screen.dart';

import '../../presentation/booking/wallet_confirmation_screen.dart';
import '../../presentation/wallet/add_amount_screen.dart';
import '../../presentation/admin/live_tracking_screen.dart';
import '../../presentation/search/location_search_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/search',
        builder: (context, state) => const LocationSearchScreen(),
      ),
      GoRoute(
        path: '/add-amount',
        builder: (context, state) => const AddAmountScreen(),
      ),
      GoRoute(
        path: '/wallet-confirmation',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          final amount = extras?['amount'] as double? ?? 0.0;
          final onConfirm = extras?['onConfirm'] as VoidCallback? ?? () {};
          return WalletConfirmationScreen(amount: amount, onConfirm: onConfirm);
        },
      ),
      // ... existing routes ...
      GoRoute(
        path: '/live-tracking/:driverId/:driverName',
        builder: (context, state) => LiveTrackingScreen(
          driverId: state.pathParameters['driverId']!,
          driverName: state.pathParameters['driverName']!,
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
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
        path: '/complain',
        builder: (context, state) => const ComplainScreen(),
      ),
      GoRoute(
        path: '/notification',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/about-us',
        builder: (context, state) => const AboutUsScreen(),
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
        path: '/saved-locations',
        builder: (context, state) => const SavedLocationsScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: '/available-cars',
        builder: (context, state) => const AvailableCarsScreen(),
      ),
      GoRoute(
        path: '/car-details',
        builder: (context, state) {
          final vehicle = state.extra as Vehicle;
          return CarDetailsScreen(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: '/booking-success',
        builder: (context, state) => const BookingSuccessScreen(),
      ),
      GoRoute(
        path: '/invoice',
        builder: (context, state) {
          final tx = state.extra as WalletTransaction?;
          return InvoiceScreen(transaction: tx);
        },
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
      GoRoute(
        path: '/trip-details',
        builder: (context, state) {
          final trip = state.extra as Trip;
          return TripDetailsScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/chat/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final extras = state.extra as Map<String, dynamic>?;
          final otherName = extras?['otherName'] as String? ?? 'Chat';
          return ChatScreen(tripId: tripId, otherName: otherName);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const TripsScreen(),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => VehiclesScreen(),
      ),
      GoRoute(
        path: '/track-drivers',
        builder: (context, state) => const TrackDriverScreen(),
      ),
      GoRoute(
        path: '/driver-home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/driver-trip-route',
        builder: (context, state) {
          final trip = state.extra as Trip;
          return DriverTripRouteScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/admin-panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/assign-booking',
        builder: (context, state) => const AssignBookingScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/delete-account',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
    ],
  );
});
