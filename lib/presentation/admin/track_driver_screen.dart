import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_models.dart';
// ── Model ─────────────────────────────────────────────────────────────────────

// ── Model ─────────────────────────────────────────────────────────────────────

class DriverStats {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final double? lat;
  final double? lng;
  final int activeBookings;
  final int completedBookings;
  final int totalBookings;

  DriverStats({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.lat,
    this.lng,
    this.activeBookings = 0,
    this.completedBookings = 0,
    this.totalBookings = 0,
  });
}

class ActiveBooking {
  final String id;
  final String status;
  final String pickupLocation;
  final String dropoffLocation;
  final String pickupDate;
  final String pickupTime;
  final String? vehicleName;
  final double? driverLat;
  final double? driverLng;
  final String createdAt;

  ActiveBooking({
    required this.id,
    required this.status,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupDate,
    required this.pickupTime,
    this.vehicleName,
    this.driverLat,
    this.driverLng,
    required this.createdAt,
  });

  factory ActiveBooking.fromJson(Map<String, dynamic> json) {
    return ActiveBooking(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      pickupLocation: (json['pickup_location'] ?? '').toString(),
      dropoffLocation: (json['dropoff_location'] ?? '').toString(),
      pickupDate: (json['pickup_date'] ?? '').toString(),
      pickupTime: (json['pickup_time'] ?? '').toString(),
      vehicleName: json['vehicle_name']?.toString(),
      driverLat: (json['driver_lat'] as num?)?.toDouble(),
      driverLng: (json['driver_lng'] as num?)?.toDouble(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final driverStatsProvider = StreamProvider.autoDispose<List<DriverStats>>((ref) {
  final supabase = Supabase.instance.client;
  final controller = StreamController<List<DriverStats>>();

  Future<void> fetchStats() async {
    try {
      // 1. Fetch all drivers
      final driversResponse = await supabase
          .from('profiles')
          .select()
          .eq('role', 'driver');
      
      final List<dynamic> driversData = driversResponse as List;

      // 2. Fetch all bookings to calculate stats
      final bookingsResponse = await supabase
          .from('bookings')
          .select('id, driver_id, status')
          .not('driver_id', 'is', null);
      
      final List<dynamic> bookingsData = bookingsResponse as List;

      // 3. Fetch driver status for live tracking
      final statusResponse = await supabase
          .from('driver_status')
          .select();
      
      final List<dynamic> statusData = statusResponse as List;

      final statsList = driversData.map((d) {
        final driverId = d['id'].toString();
        final driverBookings = bookingsData.where((b) => b['driver_id'].toString() == driverId).toList();
        
        // Find status safely
        Map<String, dynamic>? driverStatus;
        try {
          driverStatus = statusData.firstWhere((s) => s['driver_id'].toString() == driverId);
        } catch (_) {
          driverStatus = null;
        }
        
        return DriverStats(
          id: driverId,
          name: d['full_name']?.toString() ?? d['username']?.toString() ?? 'Driver',
          email: d['email']?.toString(),
          phone: d['phone']?.toString(),
          avatarUrl: d['avatar_url']?.toString(),
          lat: (driverStatus?['lat'] as num?)?.toDouble(),
          lng: (driverStatus?['lng'] as num?)?.toDouble(),
          activeBookings: driverBookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'in_progress').length,
          completedBookings: driverBookings.where((b) => b['status'] == 'completed').length,
          totalBookings: driverBookings.length,
        );
      }).toList();

      if (!controller.isClosed) controller.add(statsList);
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  fetchStats();

  // Listen to both tables
  final bookingsSub = supabase
      .channel('stats-bookings')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'bookings', callback: (_) => fetchStats())
      .subscribe();

  ref.onDispose(() {
    bookingsSub.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

final driverBookingsProvider = FutureProvider.family<List<ActiveBooking>, String>((ref, driverId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('bookings')
      .select()
      .eq('driver_id', driverId)
      .order('created_at', ascending: false);
  
  final List<dynamic> data = response as List;
  return data.map((e) => ActiveBooking.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class TrackDriverScreen extends ConsumerStatefulWidget {
  const TrackDriverScreen({super.key});

  @override
  ConsumerState<TrackDriverScreen> createState() => _TrackDriverScreenState();
}

class _TrackDriverScreenState extends ConsumerState<TrackDriverScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final driverStatsAsync = ref.watch(driverStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),
            _buildTopAppBar(context),
            SizedBox(height: 15.h),
            _buildSearchBar(),
            Expanded(
              child: driverStatsAsync.when(
                data: (stats) {
                  final filtered = stats
                      .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                  
                  if (filtered.isEmpty) return _buildEmptyState();
                  
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildDriverCard(filtered[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => _buildErrorState(e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search driver name...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverStats stats) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        onTap: () => _showDriverBookings(stats),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            stats.name.substring(0, 1).toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        title: Text(
          stats.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: [
              _buildStatBadge(Icons.directions_car, '${stats.activeBookings} Active', Colors.green),
              _buildStatBadge(Icons.check_circle, '${stats.completedBookings} Done', Colors.blue),
            ],
          ),
        ),
        trailing: SizedBox(
          width: 60.w, // Fixed width for trailing to prevent squeezing
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (stats.lat != null && stats.lng != null)
                GestureDetector(
                  onTap: () => context.push('/live-tracking/${stats.id}/${Uri.encodeComponent(stats.name)}'),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_searching, color: Theme.of(context).colorScheme.secondary, size: 18.w),
                  ),
                ),
              SizedBox(width: 4.w),
              Icon(Icons.arrow_forward_ios, size: 12.w, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLocationOnMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openDriverOnMap(ActiveBooking booking, String driverId, String driverName) {
    context.push('/live-tracking/$driverId/${Uri.encodeComponent(driverName)}');
  }

  Widget _buildStatBadge(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.w),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDriverBookings(DriverStats driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              _buildSheetHeader(driver),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final bookingsAsync = ref.watch(driverBookingsProvider(driver.id));
                    return bookingsAsync.when(
                      data: (bookings) {
                        if (bookings.isEmpty) return _buildEmptyBookingsState();
                        return ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.all(16.w),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) => _buildBookingMiniCard(bookings[index], driver),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('Error: $e')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(DriverStats driver) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.secondary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${driver.totalBookings} Total Assignments',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingMiniCard(ActiveBooking booking, DriverStats stats) {
    final color = _getStatusColor(booking.status);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${booking.id.substring(0, 8).toUpperCase()}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: Colors.blue),
                    onPressed: () => _openDriverOnMap(booking, stats.id, stats.name),
                    tooltip: 'Track Driver',
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.trip_origin, size: 14.w, color: Theme.of(context).colorScheme.secondary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  cleanLocationName(booking.pickupLocation),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(Icons.location_on, size: 14.w, color: Colors.red),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  cleanLocationName(booking.dropoffLocation),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 14.w, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                '${booking.pickupDate} at ${booking.pickupTime}',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'assigned': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return AppColors.gold;
      case 'completed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64.w, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'No drivers found',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBookingsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48.w, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              'No bookings assigned yet',
              style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final bool isNetworkError = error.toString().toLowerCase().contains('socketexception') || 
                               error.toString().toLowerCase().contains('clientexception') ||
                               error.toString().toLowerCase().contains('host lookup');

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: isNetworkError ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 64.w,
              color: isNetworkError ? Colors.blue : Colors.red,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            isNetworkError ? 'Connection Error' : 'Something went wrong',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(height: 12.h),
          Text(
            isNetworkError 
              ? 'Please check your internet connection and try again.' 
              : 'An unexpected error occurred while loading drivers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ref.invalidate(driverStatsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ));
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress': return Icons.directions_car;
      case 'confirmed':   return Icons.check_circle_outline;
      case 'pending':     return Icons.schedule;
      case 'completed':   return Icons.task_alt;
      case 'cancelled':   return Icons.cancel_outlined;
      default:            return Icons.receipt_long;
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.arrow_back, onTap: () => context.pop()),
          Text(
            'Track Drivers',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 42.w), // Balance for centering
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEA),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20.sp),
      ),
    );
  }
}
