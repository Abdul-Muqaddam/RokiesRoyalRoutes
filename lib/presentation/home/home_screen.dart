import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_models.dart';
import '../../data/services/location_service.dart';
import 'home_view_model.dart';
import '../trips/trips_screen.dart';
import '../profile/profile_screen.dart';
import '../../data/models/home_settings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildHomeContent(),
          const TripsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, -5.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, 'Home', 'assets/icons/ic_house.svg'),
            _buildNavItem(1, 'Trips', 'assets/icons/ic_car.svg'),
            _buildNavItem(2, 'Profile', 'assets/icons/ic_user.svg'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconPath) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20.w,
            height: 20.w,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final homeStateAsync = ref.watch(homeViewModelProvider);

    return homeStateAsync.when(
      data: (state) => _buildDynamicHomeContent(state),
      loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16.h),
            Text('Failed to load home data', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => ref.read(homeViewModelProvider.notifier).refresh(),
              child: Text('Retry', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicHomeContent(HomeState state) {
    final user = state.user;
    final homeSettings = ref.watch(homeSettingsProvider);

    final sectionWidgets = {
      HomeSection.header: _buildHeader(user),
      HomeSection.bookingCard: _buildBookingCard(context),
      HomeSection.vehicleSelector: _buildVehicleSelector(state),
      HomeSection.upcomingTrip: state.latestUpcomingTrip != null ? _buildUpcomingTripSection(state.latestUpcomingTrip!) : const SizedBox.shrink(),
      HomeSection.quickServices: _buildQuickServices(),
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          children: homeSettings.sections.map((section) {
            if (homeSettings.visibility[section] == false) return const SizedBox.shrink();
            return sectionWidgets[section] ?? const SizedBox.shrink();
          }).toList(),
        ),
      ),
    );
  }

  // Helper methods to clean up _buildDynamicHomeContent
  Widget _buildHeader(dynamic user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning!', style: TextStyle(color: Colors.grey, fontSize: 12.sp, fontWeight: FontWeight.w500)),
                SizedBox(height: 4.h),
                Text('Welcome back, ${user.displayName}', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 18.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            width: 44.w, height: 44.w, padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2.w)),
            child: ClipOval(child: Image.network(user.avatarUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar())),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(24.r)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Location', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12.sp, fontWeight: FontWeight.w500)),
                      SizedBox(height: 4.h),
                      ref.watch(currentLocationProvider).when(
                        data: (location) => Text(location, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 14.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        loading: () => Text('Detecting...', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                        error: (err, stack) => Text('Location unavailable', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 40.w, height: 40.w, padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: SvgPicture.asset('assets/icons/ic_location.svg', colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSecondary, BlendMode.srcIn)),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => context.push('/booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/icons/ic_plus.svg', width: 18.w, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSecondary, BlendMode.srcIn)),
                  SizedBox(width: 8.w),
                  Text('Book a Ride', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(HomeState state) {
    return Column(
      children: [
        SizedBox(height: 20.h),
        _buildSectionHeader('Select Vehicle'),
        SizedBox(height: 10.h),
        SizedBox(
          height: 180.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: state.vehicles.length,
            separatorBuilder: (context, index) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final vehicle = state.vehicles[index];
              return _buildVehicleItem(vehicle.name, vehicle.imageUrl, vehicle.passengers);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTripSection(Trip trip) {
    return Column(
      children: [
        SizedBox(height: 20.h),
        _buildSectionHeader('Upcoming Trip', trailing: 'See All'),
        SizedBox(height: 10.h),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16.w), child: _buildUpcomingTripCard(trip)),
      ],
    );
  }

  Widget _buildQuickServices() {
    return Column(
      children: [
        SizedBox(height: 20.h),
        _buildSectionHeader('Quick Services'),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildQuickAction('Airport Transfer', 'Book now', 'assets/icons/ic_flight.svg')),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildQuickAction('Hourly Charter', 'Flexible time', 'assets/icons/ic_clock.svg')),
                ],
              ),
              SizedBox(height: 8.w),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildQuickAction('Corporate Travel', 'Business class', 'assets/icons/ic_car.svg')),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildQuickAction('Special Events', 'Custom ride', 'assets/icons/ic_calendar.svg')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          if (trailing != null)
            TextButton(
              onPressed: () => _onItemTapped(1),
              child: Text(
                trailing,
                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleItem(String name, String imageUrl, int passengers) {
    return SizedBox(
      width: 140.w,
      child: Column(
        children: [
          Container(
            height: 100.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(
                imageUrl, 
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.directions_car, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3), size: 32.w),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            name, 
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text('$passengers Passengers', style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildUpcomingTripCard(Trip trip) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dividerGray, width: 2.w),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.w, 
                          height: 6.w, 
                          decoration: BoxDecoration(
                            color: _getStatusColor(trip.status), 
                            shape: BoxShape.circle
                          )
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          trip.status.name.toUpperCase(), 
                          style: TextStyle(color: _getStatusColor(trip.status), fontSize: 9.sp, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(trip.title, style: TextStyle(color: Theme.of(context).textTheme.titleSmall?.color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4.h),
                    Text(trip.dateTime, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                  ],
                ),
              ),
              Container(
                width: 56.w,
                height: 56.w,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
                child: SvgPicture.asset('assets/icons/ic_flight.svg', colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn)),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          const Divider(color: AppColors.dividerGray, thickness: 1),
          SizedBox(height: 12.h),
          Text(trip.vehicleType, style: TextStyle(color: AppColors.black, fontSize: 16.sp)),
        ],
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.confirmed:
        return Colors.green;
      case TripStatus.pending:
        return Colors.orange;
      case TripStatus.cancelled:
        return Colors.red;
      case TripStatus.past:
        return Colors.grey;
    }
  }

  Widget _buildQuickAction(String title, String subtitle, String iconAsset) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dividerGray, width: 2.w),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
            child: SvgPicture.asset(iconAsset, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn), width: 20.w, height: 20.w),
          ),
          SizedBox(height: 10.h),
          Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 14.sp)),
          SizedBox(height: 4.h),
          Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: AppColors.lightGray,
      child: Center(
        child: SvgPicture.asset('assets/icons/ic_user.svg', colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn), width: 24.w),
      ),
    );
  }
}
