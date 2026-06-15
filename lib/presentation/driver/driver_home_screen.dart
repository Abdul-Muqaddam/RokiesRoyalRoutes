import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_models.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'driver_view_model.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  String get _driverName {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};
    return meta['full_name']?.toString() ?? meta['name']?.toString() ?? 'Driver';
  }

  String get _driverInitials {
    final parts = _driverName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _driverName.isNotEmpty ? _driverName[0].toUpperCase() : 'D';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(driverViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: dashboardAsync.when(
            loading: () => Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            error: (error, _) => Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 48.sp),
                        SizedBox(height: 12.h),
                        Text('Failed to load dashboard',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () =>
                              ref.read(driverViewModelProvider.notifier).refresh(),
                          child: Text('Retry',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            data: (state) => RefreshIndicator(
              onRefresh: () => ref.read(driverViewModelProvider.notifier).refresh(),
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  SliverToBoxAdapter(child: _buildStatsRow(state)),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  SliverToBoxAdapter(child: _buildSectionHeader('Active Assignments')),
                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                  if (state.assignedTrips.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildTripCard(state.assignedTrips[index]),
                        childCount: state.assignedTrips.length,
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.gold, width: 2.w),
            ),
            child: Center(
              child: Text(
                _driverInitials,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning!',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white54),
                ),
                SizedBox(height: 2.h),
                Text(
                  _driverName,
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _logout,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white24),
              ),
              child:
                  Icon(Icons.logout_rounded, color: Colors.white70, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatsRow(DriverDashboardState state) {
    final earningsStr = state.totalEarnings > 0
        ? '\$${state.totalEarnings.toStringAsFixed(0)}'
        : '\$0';
    final ratingStr = state.rating > 0
        ? '${state.rating.toStringAsFixed(1)}★'
        : 'N/A';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: "Today's Trips",
              value: state.todayTripsCount.toString(),
              icon: Icons.route_rounded,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              label: 'Earnings',
              value: earningsStr,
              icon: Icons.account_balance_wallet_rounded,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              label: 'Rating',
              value: ratingStr,
              icon: Icons.star_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dividerGray, width: 2.w),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.secondary, size: 18.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined,
                size: 56.sp,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.4)),
            SizedBox(height: 14.h),
            Text(
              'No active assignments',
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary),
            ),
            SizedBox(height: 6.h),
            Text(
              'Go online to start receiving trips',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final statusColor = _statusColor(trip.status);
    final statusLabel = _statusLabel(trip.status);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: GestureDetector(
        onTap: () {
          context.push('/driver-trip-route', extra: trip);
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.dividerGray, width: 2.w),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
            Row(
              children: [
                // Trip reference badge
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      trip.reference ?? trip.id,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Status badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  trip.pickupTime ?? '',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                if (trip.status == TripStatus.confirmed ||
                    trip.status == TripStatus.inProgress ||
                    trip.status == TripStatus.arrived) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      context.push(
                        '/chat/${trip.id}',
                        extra: {'otherName': 'Passenger'},
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.gold,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Chat',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 14.h),
            const Divider(color: AppColors.dividerGray, thickness: 1, height: 1),
            SizedBox(height: 14.h),
            Row(
              children: [
                Column(
                  children: [
                    Icon(Icons.circle,
                        size: 10.sp,
                        color: Theme.of(context).colorScheme.secondary),
                    Container(
                        width: 1.5, height: 22.h, color: AppColors.dividerGray),
                    Icon(Icons.location_on_rounded,
                        size: 14.sp, color: Colors.grey),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanLocationName(trip.pickupLocation ?? '—'),
                        style: TextStyle(
                           fontSize: 13.sp,
                           fontWeight: FontWeight.w600,
                           color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        cleanLocationName(trip.dropoffLocation ?? '—'),
                        style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trip.price ?? '—',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[300], size: 20.sp),
                  ],
                ),
              ],
            ),
            if (trip.pickupDate != null) ...[
              SizedBox(height: 10.h),
              const Divider(
                  color: AppColors.dividerGray, thickness: 1, height: 1),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12.sp, color: Colors.grey),
                  SizedBox(width: 6.w),
                  Text(
                    trip.pickupDate!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  Color _statusColor(TripStatus status) {
    switch (status) {
      case TripStatus.confirmed:
        return const Color(0xFF4CAF50);
      case TripStatus.inProgress:
        return AppColors.gold;
      case TripStatus.pending:
        return AppColors.gold;
      case TripStatus.cancelled:
        return Colors.redAccent;
      case TripStatus.past:
        return Colors.grey;
      case TripStatus.arrived:
        return Colors.teal;
    }
  }

  String _statusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.confirmed:
        return 'Confirmed';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.pending:
        return 'Pending';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.past:
        return 'Completed';
      case TripStatus.arrived:
        return 'Driver Arrived';
    }
  }
}
