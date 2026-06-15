import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

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
          'Delete Account',
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
              'Are you sure you want to delete your account? Please read how account deletion will affect.',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Deleting your account removes personal information our database. Your email becomes permanently reserved and same email cannot be re-use to register a new account.',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black45,
                height: 1.6,
              ),
            ),
            SizedBox(height: 48.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: () => _showFinalConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336), // Branded Red
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Delete', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinalConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Deletion'),
        content: const Text('Are you absolutely sure? This action is permanent and your data will be purged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Handle final deletion logic here
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Delete Forever', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
