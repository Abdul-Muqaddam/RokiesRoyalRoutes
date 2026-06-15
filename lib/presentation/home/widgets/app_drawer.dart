import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';

import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'testing@admin.com',
      queryParameters: {
        'subject': 'Support Request - Rockies Royal',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    const Color brandYellow = Color(0xFFDC423D);

    return Drawer(
      width: 0.75.sw,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(60.r)),
      ),
      child: Column(
        children: [
          _buildHeader(context, userProfileAsync, brandYellow),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              children: [
                if (userProfileAsync.maybeWhen(data: (user) => user.role == 'admin' || user.email.toLowerCase().contains('admin'), orElse: () => false)) ...[
                  _buildMenuItem(
                    Icons.admin_panel_settings_outlined, 
                    'Admin Panel', 
                    () {
                      Scaffold.of(context).closeDrawer();
                      context.push('/admin-panel');
                    }
                  ),
                  _buildDivider(),
                ],
                _buildMenuItem(Icons.person_outline, 'Edit Profile', () {
                  Scaffold.of(context).closeDrawer();
                  context.push('/profile');
                }),
                _buildDivider(),
                _buildMenuItem(Icons.location_on_outlined, 'Address', () => context.push('/saved-locations')),
                _buildDivider(),
                _buildMenuItem(Icons.history, 'History', () => context.push('/history')),
                _buildDivider(),
                _buildMenuItem(Icons.chat_bubble_outline, 'Complain', () => context.push('/complain')),
                _buildDivider(),
                _buildMenuItem(Icons.group_outlined, 'Referral', () => context.push('/referral')),
                _buildDivider(),
                _buildMenuItem(Icons.info_outline, 'About Us', () => context.push('/about-us')),
                _buildDivider(),
                _buildMenuItem(Icons.settings_outlined, 'Settings', () => context.push('/settings')),
                _buildDivider(),
                _buildMenuItem(Icons.help_outline, 'Help and Support', _launchEmail),
                _buildDivider(),
                _buildMenuItem(Icons.logout, 'Logout', () async {
                  await ref.read(authRepositoryProvider).logout();
                  if (context.mounted) context.go('/login');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue userProfile, Color brandYellow) {
    return Container(
      padding: EdgeInsets.only(top: 50.h, left: 24.w, right: 24.w, bottom: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).closeDrawer(),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, size: 16.sp, color: Colors.black87),
                SizedBox(width: 8.w),
                Text('Back', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(height: 30.h),
          userProfile.when(
            data: (user) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: brandYellow, width: 2),
                        image: user.avatarUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(user.avatarUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: user.avatarUrl.isEmpty
                          ? Icon(Icons.person, size: 40.r, color: Colors.grey[300])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: brandYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, size: 12.r, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  user.name,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 4.h),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                ),
              ],
            ),
            loading: () => _buildProfileSkeleton(brandYellow),
            error: (_, __) => Text('Error loading profile', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSkeleton(Color brandYellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          width: 120.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 160.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black54, size: 22.sp),
      title: Text(
        title,
        style: TextStyle(fontSize: 15.sp, color: Colors.black87, fontWeight: FontWeight.w500),
      ),
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[100], height: 1);
  }
}
