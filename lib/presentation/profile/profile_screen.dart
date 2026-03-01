import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/models/user_models.dart';
import 'saved_locations_view_model.dart';
import 'location_dialogs.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProfileProvider);
    final locationsAsync = ref.watch(savedLocationsViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
      body: userAsyncValue.when(
        data: (user) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navy, Color(0xFF111111)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold, width: 4.w),
                          ),
                          child: ClipOval(
                            child: user.avatarUrl.isNotEmpty 
                              ? Image.network(user.avatarUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _defaultAvatar())
                              : _defaultAvatar(),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            user.displayName, 
                            style: TextStyle(color: AppColors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(user.totalTrips.toString(), 'Total Trips')),
                        SizedBox(width: 12.w),
                        Expanded(child: _buildStatCard(user.totalSpent, 'Spent')),
                      ],
                    )
                  ],
                ),
              ),

              // Settings Sections
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Settings', style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16.h),
                    _buildSettingItem(
                      title: 'Personal Information',
                      subtitle: 'Update your details',
                      iconAsset: 'assets/icons/ic_user.svg',
                      onTap: () => context.push('/personal-info'),
                    ),
                    SizedBox(height: 12.h),
                    _buildSettingItem(
                      title: 'Change Password',
                      subtitle: 'Update your security',
                      iconAsset: 'assets/icons/ic_lock.svg',
                      onTap: () => context.push('/change-password'),
                    ),
                    SizedBox(height: 12.h),
                    _buildSettingItem(
                      title: 'Saved Locations',
                      subtitle: locationsAsync.maybeWhen(
                        data: (locations) => locations.isEmpty 
                            ? 'No places saved' 
                            : '${locations.length} ${locations.length == 1 ? 'place' : 'places'} saved',
                        orElse: () => 'Manage your addresses',
                      ),
                      iconAsset: 'assets/icons/ic_location.svg',
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => const SavedPlacesDialog(),
                      ),
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    Text('Support', style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16.h),
                    _buildSettingItem(
                      title: 'Help Center',
                      subtitle: 'Contact support',
                      iconAsset: 'assets/icons/ic_email.svg',
                      onTap: () {},
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Logout
                    ElevatedButton(
                      onPressed: () {
                        ref.read(authRepositoryProvider).logout();
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE), // DeleteBg
                        foregroundColor: const Color(0xFFD32F2F), // DeleteText
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        minimumSize: Size(double.infinity, 50.h),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/icons/ic_logout.svg', colorFilter: const ColorFilter.mode(Color(0xFFD32F2F), BlendMode.srcIn), width: 18.w, height: 18.w),
                          SizedBox(width: 8.w),
                          Text('Sign Out', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    Center(child: Text('Rockies Royal Routes © 2025', style: TextStyle(color: Colors.grey, fontSize: 12.sp))),
                  ],
                ),
              )
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.lightGray,
      child: Center(
        child: SvgPicture.asset('assets/icons/ic_user.svg', colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn), width: 40.w, height: 40.w),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: AppColors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required String title, required String subtitle, required String iconAsset, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12.r)),
              child: SvgPicture.asset(iconAsset, colorFilter: const ColorFilter.mode(AppColors.gold, BlendMode.srcIn), width: 20.w, height: 20.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  SizedBox(height: 2.h),
                  Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                ],
              ),
            ),
            SvgPicture.asset('assets/icons/ic_chevron_right.svg', colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn), width: 20.w, height: 20.w),
          ],
        ),
      ),
    );
  }
}
