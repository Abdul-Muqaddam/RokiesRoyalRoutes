import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/models/user_models.dart';
import '../../data/providers/app_config_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_color_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textSpacing;
  late final Animation<double> _glowIntensity;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)),
    );

    _textSpacing = Tween<double>(begin: 2.0, end: 10.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart)),
    );

    _glowIntensity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine)),
    );

    _mainController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final configFetch = ref.read(appConfigProvider.notifier).fetchConfig();
      await Future.delayed(const Duration(seconds: 3)); 
      await configFetch;
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          type: DialogType.error,
          title: 'Connection Error',
          message: 'Failed to synchronize with Rockies Royal servers.',
          primaryButtonText: 'Retry',
          onPrimaryPressed: () {
             Navigator.pop(context);
             _checkAuth();
          },
        );
      }
      return;
    }

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!onboardingCompleted) {
        context.go('/onboarding');
        return;
      }
    } catch (e) {
      debugPrint('Auth error: $e');
    }

    if (!mounted) return;
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.isLoggedIn()) {
      final userRepo = ref.read(userRepositoryProvider);
      final profile = await userRepo.getUserProfile();
      if (profile.success && profile.user?.role == 'driver') {
        context.go('/driver-home');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Colors from Supabase
    final dynamicBgColor = ref.watch(appPrimaryColorProvider);
    final dynamicAccentColor = ref.watch(appColorProvider);
    final dynamicTextColor = ref.watch(appTextColorProvider);

    return Scaffold(
      backgroundColor: dynamicAccentColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle Ambient Glow (using accent color)
          AnimatedBuilder(
            animation: _glowIntensity,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: MediaQuery.of(context).size.width * 0.5 - 150.w,
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1 * _glowIntensity.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The Brand Icon
                        Container(
                          width: 90.w,
                          height: 90.w,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // Rockies Royal Branding
                        Column(
                          children: [
                            Text(
                              'ROCKIES',
                              style: GoogleFonts.outfit(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 0.9,
                              ),
                            ),
                            Text(
                              'ROYAL',
                              style: GoogleFonts.outfit(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w200,
                                color: dynamicAccentColor,
                                letterSpacing: 5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Minimalist Progress Thread (Dynamic Accent)
          Positioned(
            bottom: 100.h,
            left: 0,
            right: 0,
            child: Center(
              child: _AnimateProgressThread(color: dynamicAccentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimateProgressThread extends StatefulWidget {
  final Color color;
  const _AnimateProgressThread({required this.color});

  @override
  State<_AnimateProgressThread> createState() => _AnimateProgressThreadState();
}

class _AnimateProgressThreadState extends State<_AnimateProgressThread>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _widthAnimation = Tween<double>(begin: 0.0, end: 120.w).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 1.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.0),
                widget.color,
                widget.color.withOpacity(0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
