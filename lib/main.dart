import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/router/router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'data/local/preferences_manager.dart';
import 'data/providers/app_color_provider.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (for Stripe secret key)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env loaded successfully');
  } catch (e) {
    debugPrint('⚠️ Warning: .env file not found: $e');
  }

  // You can replace these placeholders safely!
  try {
    await Supabase.initialize(
      url: 'https://arbwxotsjasszmcftxzg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFyYnd4b3RzamFzc3ptY2Z0eHpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NzUxMzUsImV4cCI6MjA5MTM1MTEzNX0.Lj6bKGrsD_DzAF0G-nXPO5DVF_bhIuZYlLWqB2i49FE',
    );
    debugPrint('✅ Supabase initialized successfully!');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
  }

  // Initialize Firebase and Push Notifications
  await PushNotificationService().initialize();

  // ── Stripe Initialization ────────────────────────────────────────────────
  // Replace with your REAL Stripe  lishable Key from:
  // https://dashboard.stripe.com/apikeys
  Stripe.publishableKey = 'pk_test_51Sa88rHgg3zp3pK4xULu7TFFQ97014hymGbDzY5o6UkD851WR0lPxjzlMH89p9RHVX3ORxLfepZ0BhttVH9tiDQB00mJTIINSp';
  await Stripe.instance.applySettings();
  debugPrint('✅ Stripe initialized!');

  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const RockiesRoyalApp(),
    ),
  );
}

class RockiesRoyalApp extends ConsumerWidget {
  const RockiesRoyalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final customPrimaryColor = ref.watch(appColorProvider);
    final customNavyColor = ref.watch(appPrimaryColorProvider);
    final customTextColor = ref.watch(appTextColorProvider);
    final customHighlightTextColor = ref.watch(appHighlightTextColorProvider);

    return ScreenUtilInit(
      designSize: const Size(360, 800), // Updated to standard logical width
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Rockies Royal',
          theme: AppTheme.lightTheme(customPrimaryColor, customNavyColor, customTextColor, customHighlightTextColor),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          debugShowMaterialGrid: false,
          showPerformanceOverlay: false,
          checkerboardRasterCacheImages: false,
          checkerboardOffscreenLayers: false,
          showSemanticsDebugger: false,
        );
      },
    );
  }
}