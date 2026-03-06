import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/profile_settings.dart';

class ProfileCustomizationScreen extends ConsumerWidget {
  const ProfileCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(profileSettingsProvider);
    final notifier = ref.read(profileSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Profile Customization', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Drag handlers to reorder sections. Use the switches to show/hide them.',
                    style: TextStyle(fontSize: 12.sp, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: EdgeInsets.all(16.w),
              onReorder: notifier.reorderSections,
              buildDefaultDragHandles: false,
              children: settings.sections.map((section) {
                return _SectionTile(
                  key: ValueKey(section),
                  section: section,
                  isVisible: settings.visibility[section] ?? true,
                  onToggle: (val) => notifier.updateVisibility(section, val),
                  settings: settings,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final ProfileSection section;
  final bool isVisible;
  final ValueChanged<bool> onToggle;
  final ProfileSettings settings;

  const _SectionTile({
    required super.key,
    required this.section,
    required this.isVisible,
    required this.onToggle,
    required this.settings,
  });

  String _getSectionName(ProfileSection section) {
    switch (section) {
      case ProfileSection.header: return 'User Profile Header';
      case ProfileSection.accountSettings: return 'Account Settings List';
      case ProfileSection.support: return 'Support & Help Center';
      case ProfileSection.logout: return 'Logout Button';
      case ProfileSection.footer: return 'Copyright Footer';
    }
  }

  IconData _getSectionIcon(ProfileSection section) {
    switch (section) {
      case ProfileSection.header: return Icons.account_circle_outlined;
      case ProfileSection.accountSettings: return Icons.manage_accounts_outlined;
      case ProfileSection.support: return Icons.support_agent_outlined;
      case ProfileSection.logout: return Icons.logout_outlined;
      case ProfileSection.footer: return Icons.copyright_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.dividerGray),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: settings.sections.indexOf(section),
              child: Icon(Icons.drag_handle, color: Colors.grey),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(_getSectionIcon(section), color: Theme.of(context).colorScheme.secondary, size: 20.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                _getSectionName(section),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Switch(
              value: isVisible,
              onChanged: onToggle,
              activeColor: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
