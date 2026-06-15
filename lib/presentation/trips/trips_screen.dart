import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/booking_models.dart';
import 'trips_view_model.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Completed, 2: Cancelled

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);

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
          'History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 10.h),
          _buildSegmentedControl(brandYellow),
          SizedBox(height: 20.h),
          Expanded(
            child: _buildTripList(brandYellow),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(Color brandYellow) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: brandYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Upcoming', brandYellow),
          _buildTabItem(1, 'Completed', brandYellow),
          _buildTabItem(2, 'Cancelled', brandYellow),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, Color brandYellow) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? brandYellow : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black45,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripList(Color brandYellow) {
    // In a real app, you would filter the list from the viewModel based on _selectedTab
    // For now, I'll use the viewModel data to populate the list with mockup-style cards
    final tripsStateAsync = ref.watch(tripsViewModelProvider);

    return tripsStateAsync.when(
      data: (state) {
        // Filter logic based on tab (assuming state.trips has status property)
        final filteredTrips = state.trips.where((trip) {
          if (_selectedTab == 0) return trip.status == TripStatus.confirmed || trip.status == TripStatus.pending;
          if (_selectedTab == 1) return trip.status == TripStatus.past;
          if (_selectedTab == 2) return trip.status == TripStatus.cancelled;
          return true;
        }).toList();

        if (filteredTrips.isEmpty) {
          return Center(
            child: Text(
              'No history found',
              style: TextStyle(color: Colors.black26, fontSize: 16.sp),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: filteredTrips.length,
          itemBuilder: (context, index) {
            final trip = filteredTrips[index];
            return _buildHistoryCard(trip, brandYellow);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildHistoryCard(Trip trip, Color brandYellow) {
    String statusText = '';
    Color statusColor = Colors.black45;

    if (_selectedTab == 0) {
      statusText = trip.dateTime; // e.g. "Today at 09:20 am"
    } else if (_selectedTab == 1) {
      statusText = 'Done';
      statusColor = const Color(0xFF4CAF50); // Green
    } else {
      statusText = 'Cancel';
      statusColor = const Color(0xFFF44336); // Red
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: brandYellow.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title, // User/Driver Name
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  trip.vehicleType, // Vehicle Model
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black26,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
