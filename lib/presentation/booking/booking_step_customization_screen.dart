import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_settings.dart';
import '../../data/providers/app_config_provider.dart';

class BookingStepCustomizationScreen extends ConsumerWidget {
  final int stepIndex;
  const BookingStepCustomizationScreen({super.key, required this.stepIndex});

  String _getStepTitle(int index) {
    switch (index) {
      case 1: return 'Location Selection Customization';
      case 2: return 'Schedule Picking Customization';
      case 3: return 'Vehicle Choice Customization';
      case 4: return 'Checkout Summary Customization';
      default: return 'Step Customization';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(bookingSettingsProvider);
    final notifier = ref.read(bookingSettingsProvider.notifier);

    List<dynamic> currentOrder;
    Map<dynamic, bool> currentVisibility;

    switch (stepIndex) {
      case 1:
        currentOrder = settings.step1Order;
        currentVisibility = settings.step1Visibility;
        break;
      case 2:
        currentOrder = settings.step2Order;
        currentVisibility = settings.step2Visibility;
        break;
      case 3:
        currentOrder = settings.step3Order;
        currentVisibility = settings.step3Visibility;
        break;
      case 4:
        currentOrder = settings.step4Order;
        currentVisibility = settings.step4Visibility;
        break;
      default:
        currentOrder = [];
        currentVisibility = {};
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(_getStepTitle(stepIndex), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    'Drag handlers to reorder sections within this step. Use the switches to show/hide them.',
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
                notifier.reorderSections(stepIndex, oldIdx, newIdx);
                ref.read(appConfigProvider.notifier).updateConfig(
                  ref.read(appConfigProvider.notifier).createConfigFromLocal()
                );
              },
              buildDefaultDragHandles: false,
              children: currentOrder.map((section) {
                return _SectionTile(
                  key: ValueKey(section),
                  stepIndex: stepIndex,
                  section: section,
                  isVisible: currentVisibility[section] ?? true,
                  onToggle: (val) {
                    notifier.updateVisibility(stepIndex, section, val);
                    ref.read(appConfigProvider.notifier).updateConfig(
                      ref.read(appConfigProvider.notifier).createConfigFromLocal()
                    );
                  },
                  currentOrder: currentOrder,
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
  final int stepIndex;
  final dynamic section;
  final bool isVisible;
  final ValueChanged<bool> onToggle;
  final List<dynamic> currentOrder;

  const _SectionTile({
    required super.key,
    required this.stepIndex,
    required this.section,
    required this.isVisible,
    required this.onToggle,
    required this.currentOrder,
  });

  String _getSectionName(dynamic section) {
    if (section is BookingStep1Section) {
      switch (section) {
        case BookingStep1Section.header: return 'Welcome Title';
        case BookingStep1Section.locationFields: return 'Pickup & Destination Fields';
        case BookingStep1Section.recentPlaces: return 'Recent Destinations';
        case BookingStep1Section.savedPlaces: return 'Saved Places Grid';
        case BookingStep1Section.distanceCard: return 'Distance & Duration Card';
        case BookingStep1Section.saveLocation: return 'Save Location Button';
      }
    } else if (section is BookingStep2Section) {
      switch (section) {
        case BookingStep2Section.timeType: return 'Time Type Toggle (Now/Schedule)';
        case BookingStep2Section.dateSelector: return 'Date Selection List';
        case BookingStep2Section.timeGrid: return 'Time Selection Grid';
        case BookingStep2Section.customTime: return 'Custom Time Button';
        case BookingStep2Section.infoBox: return 'Chauffeur Grace Period Info';
      }
    } else if (section is BookingStep3Section) {
      switch (section) {
        case BookingStep3Section.categoryTabs: return 'Vehicle Category Tabs';
        case BookingStep3Section.vehicleList: return 'Vehicle List & Cards';
      }
    } else if (section is BookingStep4Section) {
      switch (section) {
        case BookingStep4Section.summaryCard: return 'Booking Summary Card';
        case BookingStep4Section.tripDetails: return 'Passenger & Luggage Counters';
        case BookingStep4Section.personalDetails: return 'Personal Information Fields';
        case BookingStep4Section.noteField: return 'Additional Note Field';
        case BookingStep4Section.paymentMethods: return 'Payment Gateway Selector';
        case BookingStep4Section.requirements: return 'Terms & Conditions Grid';
      }
    }
    return section.toString();
  }

  IconData _getSectionIcon(dynamic section) {
     if (section is BookingStep1Section) return Icons.location_on_outlined;
     if (section is BookingStep2Section) return Icons.schedule_outlined;
     if (section is BookingStep3Section) return Icons.directions_car_outlined;
     if (section is BookingStep4Section) return Icons.receipt_long_outlined;
     return Icons.drag_handle;
  }

  @override
  Widget build(BuildContext context) {
    bool isMandatory = false; // All sections are now toggleable as per user request

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
              index: currentOrder.indexOf(section),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSectionName(section),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
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
