import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Privacy Policy',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Rockies Royal',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24.h),
            _buildSectionText(
              'At Rockies Royal, accessible from rockiesroyal.com, one of our main priorities is the privacy of our visitors. This Privacy Policy document contains types of information that is collected and recorded by Rockies Royal and how we use it.',
            ),
            SizedBox(height: 16.h),
            _buildSectionText(
              'If you have additional questions or require more information about our Privacy Policy, do not hesitate to contact us.',
            ),
            SizedBox(height: 16.h),
            _buildSectionText(
              'This Privacy Policy applies only to our online activities and is valid for visitors to our website with regards to the information that they shared and/or collect in Rockies Royal. This policy is not applicable to any information collected offline or via channels other than this website.',
            ),
            SizedBox(height: 16.h),
            _buildSectionText(
              'Our Privacy Policy was created with the help of our legal team to ensure your data is always protected and used only for the purpose of providing you with the best concierge and transport services.',
            ),
            SizedBox(height: 32.h),
            Text(
              'Information we collect',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            _buildSectionText(
              'The personal information that you are asked to provide, and the reasons why you are asked to provide it, will be made clear to you at the point we ask you to provide your personal information.',
            ),
            SizedBox(height: 16.h),
            _buildSectionText(
              'If you contact us directly, we may receive additional information about you such as your name, email address, phone number, the contents of the message and/or attachments you may send us, and any other information you may choose to provide.',
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        color: Colors.black54,
        height: 1.6,
      ),
    );
  }
}
