import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80.w,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            children: [
              SizedBox(width: 20.w),
              Icon(Icons.arrow_back_ios, color: Colors.black87, size: 18.sp),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'About Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Logo Placeholder
            Container(
              width: 120.r,
              height: 120.r,
              decoration: BoxDecoration(
                color: brandYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.directions_car_filled, color: brandYellow, size: 60.sp),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Rockies Royal',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Premium Concierge & Transport',
              style: TextStyle(
                fontSize: 14.sp,
                color: brandYellow,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 40.h),
            _buildAboutSection(
              'Our Story',
              'Rockies Royal was founded with a single mission: to redefine premium transportation. We combine cutting-edge technology with elite concierge service to ensure every journey is more than just a ride—it\'s an experience.',
            ),
            SizedBox(height: 32.h),
            _buildAboutSection(
              'Our Vision',
              'To become the world\'s most trusted luxury transport partner, delivering seamless, safe, and sophisticated travel solutions at the touch of a button.',
            ),
            SizedBox(height: 48.h),
            Divider(color: Colors.grey[200]),
            SizedBox(height: 24.h),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12.sp, color: Colors.black26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              '© 2024 Rockies Royal. All rights reserved.',
              style: TextStyle(fontSize: 12.sp, color: Colors.black12),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          content,
          style: TextStyle(
            fontSize: 15.sp,
            color: Colors.black54,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
