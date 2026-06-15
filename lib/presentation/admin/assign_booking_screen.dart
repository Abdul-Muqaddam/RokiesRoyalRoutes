import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/models/booking_models.dart';
import '../../data/models/user_models.dart';
import '../../core/services/push_notification_service.dart';
import '../../data/repositories/notification_repository.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final unassignedBookingsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('bookings')
      .select()
      .filter('driver_id', 'is', null)
      .not('status', 'eq', 'cancelled')
      .order('created_at', ascending: false);

  final List<dynamic> data = response as List;
  return data.map((json) {
    final rawStatus = (json['status'] ?? 'pending').toString().toLowerCase();
    TripStatus status = TripStatus.pending;
    if (rawStatus == 'confirmed') status = TripStatus.confirmed;
    if (rawStatus == 'completed' || rawStatus == 'past') status = TripStatus.past;
    if (rawStatus == 'cancelled') status = TripStatus.cancelled;

    return Trip(
      id: json['id'].toString(),
      title: '${json['pickup_location']} → ${json['dropoff_location']}',
      dateTime: '${json['pickup_date']} at ${json['pickup_time']}',
      status: status,
      vehicleType: json['vehicle_id']?.toString() ?? 'Vehicle',
      pickupDate: json['pickup_date'],
      pickupTime: json['pickup_time'],
      pickupLocation: json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      price: '${json['currency'] ?? 'CAD'} ${json['total_price'] ?? '0.00'}',
      reference: '#${json['id'].toString().substring(0, 8).toUpperCase()}',
      userId: json['user_id']?.toString(),
    );
  }).toList();
});

final availableDriversProvider = FutureProvider.autoDispose<List<UserDto>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getDrivers();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AssignBookingScreen extends ConsumerStatefulWidget {
  const AssignBookingScreen({super.key});

  @override
  ConsumerState<AssignBookingScreen> createState() => _AssignBookingScreenState();
}

class _AssignBookingScreenState extends ConsumerState<AssignBookingScreen> {
  Trip? _selectedTrip;
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(unassignedBookingsProvider);
    final driversAsync = ref.watch(availableDriversProvider);

    const Color brandYellow = Color(0xFFDC423D);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),
            _buildTopAppBar(context),
            SizedBox(height: 8.h),
            _buildSubtitleBanner(),
            SizedBox(height: 8.h),
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) {
                  if (bookings.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final trip = bookings[index];
                      final isSelected = _selectedTrip?.id == trip.id;
                      return _buildTripCard(trip, isSelected);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: \$e')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedTrip != null
          ? _buildAssignmentPanel(driversAsync)
          : null,
    );
  }

  Widget _buildSubtitleBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Text(
        'Select a pending booking to assign a driver',
        style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _buildCircleButton(Icons.arrow_back, onTap: () => context.pop()),
          Expanded(
            child: Center(
              child: Text(
                'Assign Bookings',
                style: TextStyle(color: Colors.black, fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 42.w),
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

  Widget _buildTripCard(Trip trip, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTrip = isSelected ? null : trip),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trip.reference ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                _buildProgressIndicator(trip.status),
              ],
            ),
            SizedBox(height: 8.h),
            _buildLocationRow(Icons.trip_origin, cleanLocationName(trip.pickupLocation ?? '')),
            Padding(
              padding: EdgeInsets.only(left: 7.w),
              child: Container(width: 1, height: 16.h, color: Colors.grey[300]),
            ),
            _buildLocationRow(Icons.location_on, cleanLocationName(trip.dropoffLocation ?? '')),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14.w, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          trip.dateTime,
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  trip.price ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(TripStatus status) {
    int currentStep = 0;
    if (status == TripStatus.confirmed) currentStep = 1;
    if (status == TripStatus.past) currentStep = 2;
    if (status == TripStatus.cancelled) return _buildStatusBadge(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusText(status),
        SizedBox(width: 8.w),
        _buildStepDot(currentStep >= 0, "Pending"),
        _buildStepLine(currentStep >= 1),
        _buildStepDot(currentStep >= 1, "Assigned"),
        _buildStepLine(currentStep >= 2),
        _buildStepDot(currentStep >= 2, "Done"),
      ],
    );
  }

  Widget _buildStatusText(TripStatus status) {
    String text = 'Pending';
    Color color = AppColors.gold;
    
    if (status == TripStatus.confirmed) {
      text = 'Assigned';
      color = Theme.of(context).colorScheme.secondary;
    } else if (status == TripStatus.past) {
      text = 'Completed';
      color = Colors.green;
    } else if (status == TripStatus.cancelled) {
      text = 'Cancelled';
      color = Colors.red;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildStepDot(bool active, String label) {
    final color = active ? Theme.of(context).colorScheme.secondary : Colors.grey[300]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)] : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 12.w,
      height: 2.h,
      color: active ? Theme.of(context).colorScheme.secondary : Colors.grey[200],
    );
  }

  Widget _buildStatusBadge(TripStatus status) {
    Color color = status == TripStatus.cancelled ? Colors.red : Colors.grey;
    String text = status == TripStatus.cancelled ? 'Cancelled' : 'Past';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String address) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: icon == Icons.location_on ? Colors.red : Colors.grey),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            address,
            style: TextStyle(fontSize: 13.sp, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentPanel(AsyncValue<List<UserDto>> driversAsync) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign Driver to ${_selectedTrip?.reference}',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          driversAsync.when(
            data: (drivers) {
              print('DEBUG: UI received ${drivers.length} drivers for selection.');
              if (drivers.isEmpty) {
                return Column(
                  children: [
                    const Text('No available drivers found.'),
                    SizedBox(height: 8.h),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(availableDriversProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Drivers'),
                    ),
                  ],
                );
              }
              return SizedBox(
                height: 110.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return _buildDriverAvatar(driver);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Column(
              children: [
                Text('Error: $e'),
                TextButton(
                  onPressed: () => ref.invalidate(availableDriversProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverAvatar(UserDto driver) {
    return GestureDetector(
      onTap: _isAssigning ? null : () => _assignBooking(driver),
      child: Container(
        width: 80.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            ),
            SizedBox(height: 4.h),
            Text(
              driver.name,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignBooking(UserDto driver) async {
    if (_selectedTrip == null) return;
    
    final trip = _selectedTrip!;
    final tripRef = trip.reference;
    setState(() => _isAssigning = true);
    
    final success = await ref.read(bookingRepositoryProvider).assignDriver(
      trip.id,
      driver.uid!,
      status: 'confirmed',
    );

    if (mounted) {
      setState(() => _isAssigning = false);
      if (success) {
        // Send notifications
        final adminUserId = Supabase.instance.client.auth.currentUser?.id;
        final driverId = driver.uid;
        
        // 1. Notify Driver
        if (driverId != null) {
          final driverTitle = 'New Ride Assigned! 🚗';
          final driverBody = 'You have been assigned to ride ${trip.reference} on ${trip.dateTime} (${cleanLocationName(trip.pickupLocation)} → ${cleanLocationName(trip.dropoffLocation)}).';
          
          ref.read(notificationRepositoryProvider).insert(
            userId: driverId,
            title: driverTitle,
            body: driverBody,
            type: 'booking',
          ).catchError((e) => debugPrint('❌ Error inserting driver notification DB: $e'));

          PushNotificationService().sendPushNotification(
            recipientUserId: driverId,
            title: driverTitle,
            body: driverBody,
          ).catchError((e) => debugPrint('❌ Error sending driver push: $e'));
        }

        // 2. Notify Admin
        if (adminUserId != null) {
          final adminTitle = 'Driver Assigned Successfully! 👤';
          final adminBody = '${driver.name} has been successfully assigned to ride ${trip.reference} to ${cleanLocationName(trip.dropoffLocation)}.';
          
          ref.read(notificationRepositoryProvider).insert(
            userId: adminUserId,
            title: adminTitle,
            body: adminBody,
            type: 'booking',
          ).catchError((e) => debugPrint('❌ Error inserting admin notification DB: $e'));

          PushNotificationService().sendPushNotification(
            recipientUserId: adminUserId,
            title: adminTitle,
            body: adminBody,
          ).catchError((e) => debugPrint('❌ Error sending admin push: $e'));
        }

        // 3. Notify Passenger (User)
        final passengerId = trip.userId;
        if (passengerId != null) {
          final userTitle = 'Driver Assigned! 🚗';
          final userBody = 'Driver ${driver.name} has been assigned to your ride ${trip.reference} (${cleanLocationName(trip.pickupLocation)} → ${cleanLocationName(trip.dropoffLocation)}).';
          
          ref.read(notificationRepositoryProvider).insert(
            userId: passengerId,
            title: userTitle,
            body: userBody,
            type: 'booking',
          ).catchError((e) => debugPrint('❌ Error inserting passenger notification DB: $e'));

          PushNotificationService().sendPushNotification(
            recipientUserId: passengerId,
            title: userTitle,
            body: userBody,
          ).catchError((e) => debugPrint('❌ Error sending passenger push: $e'));
        }

        _showSuccessDialog(driver.name, tripRef ?? 'Booking');
        setState(() => _selectedTrip = null);
        ref.invalidate(unassignedBookingsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to assign driver. Please try again.')),
        );
      }
    }
  }

  void _showSuccessDialog(String driverName, String tripRef) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 40.w),
              ),
              SizedBox(height: 20.h),
              Text(
                'Assignment Successful',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'You have successfully assigned $driverName to $tripRef.',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: Text('Great!', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64.w, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'All bookings are assigned!',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
