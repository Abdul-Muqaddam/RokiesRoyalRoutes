import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);

    final List<Map<String, dynamic>> settingsItems = [
      {'title': 'Change Password', 'route': '/change-password'},
      {'title': 'Change Language', 'route': '/language'},
      {'title': 'Privacy Policy', 'route': '/privacy-policy'},
      {'title': 'Contact Us', 'route': '/contact-us'},
      {'title': 'Delete Account', 'route': '/delete-account', 'isDestructive': true},
    ];

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
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        itemCount: settingsItems.length,
        itemBuilder: (context, index) {
          final item = settingsItems[index];
          return _buildSettingsItem(context, item, brandYellow);
        },
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, Map<String, dynamic> item, Color brandYellow) {
    final bool isDestructive = item['isDestructive'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: brandYellow.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          if (item['route'] != null) {
            context.push(item['route']);
          } else if (isDestructive) {
            _showDeleteConfirmation(context);
          }
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        title: Text(
          item['title'],
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red[400] : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: Colors.black45,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Handle account deletion
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
