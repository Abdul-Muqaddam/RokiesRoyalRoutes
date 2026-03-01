import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_models.dart';
import 'trips_view_model.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsStateAsync = ref.watch(tripsViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Trips',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  tripsStateAsync.when(
                    data: (state) => Row(
                      children: [
                        Expanded(
                          child: _TripTabButton(
                            text: 'All',
                            isSelected: state.selectedTab == 0,
                            onClick: () => ref.read(tripsViewModelProvider.notifier).selectTab(0),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _TripTabButton(
                            text: 'Upcoming',
                            isSelected: state.selectedTab == 1,
                            onClick: () => ref.read(tripsViewModelProvider.notifier).selectTab(1),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _TripTabButton(
                            text: 'Past',
                            isSelected: state.selectedTab == 2,
                            onClick: () => ref.read(tripsViewModelProvider.notifier).selectTab(2),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.dividerGray, height: 1),
            Expanded(
              child: tripsStateAsync.when(
                data: (state) {
                  if (state.trips.isEmpty) {
                    return const Center(
                      child: Text(
                        'No trips found',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(20.w),
                    itemCount: state.trips.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      return _TripCard(trip: state.trips[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16.h),
                      const Text('Failed to load trips'),
                      TextButton(
                        onPressed: () => ref.read(tripsViewModelProvider.notifier).refresh(),
                        child: const Text('Retry', style: TextStyle(color: AppColors.gold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: ElevatedButton(
                onPressed: () => context.push('/booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.gold,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text(
                  'Book New Trip',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripTabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onClick;

  const _TripTabButton({
    required this.text,
    required this.isSelected,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: ElevatedButton(
        onPressed: onClick,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.gold : AppColors.lightGray,
          foregroundColor: isSelected ? AppColors.navy : Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.dividerGray, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(status: trip.status),
                Text(
                  trip.reference ?? '',
                  style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              trip.title,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              trip.dateTime,
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          trip.pickupLocation ?? 'Unknown Location',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_location.svg',
                        width: 10.w,
                        colorFilter: const ColorFilter.mode(AppColors.navy, BlendMode.srcIn),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          trip.dropoffLocation ?? 'Unknown Destination',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.vehicleType,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  trip.price ?? '',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to details
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (trip.status == TripStatus.past) ...[
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.dividerGray),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Rebook',
                        style: TextStyle(color: Colors.grey, fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TripStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case TripStatus.confirmed:
        color = Colors.green;
        text = 'Confirmed';
        break;
      case TripStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TripStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case TripStatus.past:
        color = Colors.grey;
        text = 'Past';
        break;
    }

    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
