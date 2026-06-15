import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AdminPanelScreen extends StatelessWidget {
  final bool isTab;
  
  const AdminPanelScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),
            _buildTopAppBar(context),
            SizedBox(height: 15.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 24.w, bottom: 120.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
              'Management Tools',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildAdminItem(
              context,
              title: 'Customize App',
              subtitle: 'Manage app sections and visibility',
              iconAsset: 'assets/icons/ic_customization.svg',
              onTap: () => context.push('/customization'),
            ),
            SizedBox(height: 12.h),
            _buildAdminItem(
              context,
              title: 'Track Drivers',
              subtitle: 'Monitor live bookings and driver locations',
              iconAsset: 'assets/icons/ic_location.svg',
              onTap: () => context.push('/track-drivers'),
            ),
            SizedBox(height: 12.h),
            _buildAdminItem(
              context,
              title: 'Assign Bookings',
              subtitle: 'Dispatch pending bookings to drivers',
              iconAsset: 'assets/icons/ic_user.svg',
              onTap: () => context.push('/assign-booking'),
            ),
            SizedBox(height: 24.h),
            _buildInfoCard(
              context,
              title: 'Admin Access',
              description: 'You are logged in with administrative privileges. Any changes made here will affect the application experience for all users.',
            ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    const Color brandYellow = Color(0xFFDC423D);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: brandYellow.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: brandYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                iconAsset,
                colorFilter: const ColorFilter.mode(
                  brandYellow,
                  BlendMode.srcIn,
                ),
                width: 22.w,
                height: 22.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String description}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            isTab ? Icons.menu : Icons.arrow_back, 
            onTap: () {
              if (isTab) {
                Scaffold.of(context).openDrawer();
              } else {
                context.pop();
              }
            }
          ),
          Text(
            'Admin Panel',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 42.w), // Balance for centering
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEA),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20.sp),
      ),
    );
  }
}
