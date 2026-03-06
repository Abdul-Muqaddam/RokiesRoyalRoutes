import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/home_settings.dart';
import '../../data/providers/app_config_provider.dart';

class HomeScreenCustomizationScreen extends ConsumerWidget {
  const HomeScreenCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(homeSettingsProvider);
    final notifier = ref.read(homeSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Home Customization', style: TextStyle(fontWeight: FontWeight.bold)),
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
              onReorder: (oldIdx, newIdx) {
                notifier.reorderSections(oldIdx, newIdx);
                ref.read(appConfigProvider.notifier).updateConfig(
                  ref.read(appConfigProvider.notifier).createConfigFromLocal()
                );
              },
              buildDefaultDragHandles: false,
              children: settings.sections.map((section) {
                return _SectionTile(
                  key: ValueKey(section),
                  section: section,
                  isVisible: settings.visibility[section] ?? true,
                  onToggle: (val) {
                    notifier.updateVisibility(section, val);
                    ref.read(appConfigProvider.notifier).updateConfig(
                      ref.read(appConfigProvider.notifier).createConfigFromLocal()
                    );
                  },
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
  final HomeSection section;
  final bool isVisible;
  final ValueChanged<bool> onToggle;
  final HomeSettings settings;

  const _SectionTile({
    required super.key,
    required this.section,
    required this.isVisible,
    required this.onToggle,
    required this.settings,
  });

  String _getSectionName(HomeSection section) {
    switch (section) {
      case HomeSection.header: return 'User Welcome Header';
      case HomeSection.bookingCard: return 'Booking Card';
      case HomeSection.vehicleSelector: return 'Vehicle Display';
      case HomeSection.upcomingTrip: return 'Upcoming Trip Card';
      case HomeSection.quickServices: return 'Quick Services Grid';
    }
  }

  IconData _getSectionIcon(HomeSection section) {
    switch (section) {
      case HomeSection.header: return Icons.person_outline;
      case HomeSection.bookingCard: return Icons.directions_car_filled_outlined;
      case HomeSection.vehicleSelector: return Icons.grid_view_outlined;
      case HomeSection.upcomingTrip: return Icons.event_note_outlined;
      case HomeSection.quickServices: return Icons.dashboard_customize_outlined;
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