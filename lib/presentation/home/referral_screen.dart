import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);
    const String referralCode = 'RkMFucd';

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
          'Referral',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Text(
              'Refer a friend and Earn \$20',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    referralCode,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard')),
                      );
                    },
                    child: Icon(Icons.copy_outlined, color: Colors.black45, size: 20.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: () {
                  Share.share(
                    'Join me on Rockies Royal and earn \$20 on your first journey! Use my referral code: $referralCode\n\nDownload now: https://rockiesroyal.com/join?ref=$referralCode',
                    subject: 'Rockies Royal Referral',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Invite', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 48.h),
            _buildReferralInfo(brandYellow),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralInfo(Color brandYellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        SizedBox(height: 16.h),
        _buildInfoStep(
          '1',
          'Share your code',
          'Send your unique referral code to your friends and family.',
          brandYellow,
        ),
        SizedBox(height: 24.h),
        _buildInfoStep(
          '2',
          'Friend joins',
          'Your friend registers using your code and completes their first journey.',
          brandYellow,
        ),
        SizedBox(height: 24.h),
        _buildInfoStep(
          '3',
          'Earn Reward',
          'You both receive \$20 credit in your Rockies Royal wallet!',
          brandYellow,
        ),
      ],
    );
  }

  Widget _buildInfoStep(String number, String title, String description, Color brandYellow) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.r,
          height: 28.r,
          decoration: BoxDecoration(
            color: brandYellow.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(color: brandYellow, fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(fontSize: 13.sp, color: Colors.black45, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
