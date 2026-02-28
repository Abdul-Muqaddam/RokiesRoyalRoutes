import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final String imageUrl;
  final String buttonText;
  final bool showSkip;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.buttonText,
    this.showSkip = true,
  });
}

final List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Premium Fleet at Your Service',
    description: 'Experience unparalleled comfort with our meticulously maintained collection of luxury vehicles',
    imageUrl: 'https://storage.googleapis.com/uxpilot-auth.appspot.com/f83471f3ec-dc37248d325e8dbe5c12.png',
    buttonText: 'Continue',
  ),
  OnboardingPageData(
    title: 'Professional Chauffeurs',
    description: 'Our expertly trained drivers ensure a smooth, safe, and discreet journey every time',
    imageUrl: 'https://storage.googleapis.com/uxpilot-auth.appspot.com/95454c7c78-e74374d6e8bc6d12792c.png',
    buttonText: 'Continue',
  ),
  OnboardingPageData(
    title: 'Always On Time',
    description: 'Punctuality is our promise. Real-time tracking and proactive scheduling guarantee timely arrivals',
    imageUrl: 'https://storage.googleapis.com/uxpilot-auth.appspot.com/d1dbd789ed-19eab019d592518d01c3.png',
    buttonText: 'Get Started',
    showSkip: false,
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
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: Image.network(
                            page.imageUrl,
                            height: 240.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(height: 240.h, color: AppColors.lightGray, child: const Center(child: Icon(Icons.error))),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          page.title,
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indicators
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingPages.length,
                  (index) => Container(
                    margin: EdgeInsets.only(right: 6.w),
                    height: 6.h,
                    width: _currentPage == index ? 24.w : 8.w,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.gold : AppColors.gold.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              ),
            ),
            
            // Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w).copyWith(bottom: 24.h),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < onboardingPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      minimumSize: Size(double.infinity, 48.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      onboardingPages[_currentPage].buttonText,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  if (_currentPage < onboardingPages.length - 1)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            onboardingPages.length - 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(height: 48.h), // Spacer to maintain consistent layout height
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
