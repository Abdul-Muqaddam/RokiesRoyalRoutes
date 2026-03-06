import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'data/local/preferences_manager.dart';
import 'data/providers/app_color_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      designSize: const Size(300, 800), // Matching Android's sdp 300dp baseline
      minTextAdapt: true,
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
