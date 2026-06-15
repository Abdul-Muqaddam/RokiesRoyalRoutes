import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final String imageUrl;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}

final List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Anywhere you are',
    description: 'Sell houses easily with the help of Listenoryx and to make this line big I am writing more.',
    imageUrl: 'assets/images/first_onboarding.png',
  ),
  OnboardingPageData(
    title: 'At anytime',
    description: 'Sell houses easily with the help of Listenoryx and to make this line big I am writing more.',
    imageUrl: 'assets/images/second_onboarding.png',
  ),
  OnboardingPageData(
    title: 'Book your car',
    description: 'Sell houses easily with the help of Listenoryx and to make this line big I am writing more.',
    imageUrl: 'assets/images/third_onboarding.png',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.outfit(
                        color: AppColors.mediumGray,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = onboardingPages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        Image.asset(
                          page.imageUrl,
                          height: 280.h,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 48.h),
                        
                        // Text Content
                        Text(
                          page.title,
                          style: GoogleFonts.outfit(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          page.description,
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            color: AppColors.mediumGray,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Action Area
            Padding(
              padding: EdgeInsets.only(bottom: 60.h),
              child: _buildProgressButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressButton() {
    final isLast = _currentPage == onboardingPages.length - 1;
    final targetProgress = (_currentPage + 1) / onboardingPages.length;

    return GestureDetector(
      onTap: () {
        if (!isLast) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuart,
          );
        } else {
          _completeOnboarding();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Animated Progress Ring
          SizedBox(
            width: 80.w,
            height: 80.w,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              tween: Tween<double>(begin: 0, end: targetProgress),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3.w,
                  backgroundColor: AppColors.gold.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                );
              },
            ),
          ),
          // Inner Button
          Container(
            width: 62.w,
            height: 62.w,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isLast 
                ? Text(
                    'Go',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  )
                : Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 26.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
