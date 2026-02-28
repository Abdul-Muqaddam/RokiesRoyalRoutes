import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.fastOutSlowIn));

    _scaleController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3)); // Same 3 sec delay as Kotlin
    if (!context.mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!context.mounted) return;

      if (!onboardingCompleted) {
        context.go('/onboarding');
        return;
      }
    } catch (e) {
      debugPrint('SharedPreferences error ignored: $e');
    }

    if (!mounted) return;
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.isLoggedIn()) {
      if (mounted) context.go('/home');
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // assuming background color based off Material Theme
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6.r,
                          offset: Offset(0, 3.h),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 36.w,
                      height: 36.w,
                      child: SvgPicture.asset(
                        'assets/icons/ic_crown.svg',
                        colorFilter: const ColorFilter.mode(AppColors.navy, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'ROCKIES',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                    letterSpacing: 2.w,
                  ),
                ),
                Text(
                  'ROYAL ROUTES',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gold,
                    letterSpacing: 4.w,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 60.h),
              child: PulsingDots(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingDots extends StatefulWidget {
  final Color color;
  const PulsingDots({super.key, required this.color});

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // calculating an offset phase delay
              double phase = (index * 0.25);
              double rawVal = _controller.value - phase;
              if (rawVal < 0) rawVal += 1.0;
              // smooth it
              double scale = 0.4 + (0.6 * rawVal);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
