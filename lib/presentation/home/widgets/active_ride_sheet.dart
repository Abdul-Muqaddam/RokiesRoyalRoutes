import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/booking_models.dart';
import '../../../data/models/user_models.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../../admin/live_tracking_screen.dart';
import '../../../domain/repositories/booking_repository.dart';

final driverInfoProvider = FutureProvider.family<UserDto?, String>((ref, driverId) async {
  final repo = ref.watch(userRepositoryProvider);
  return await repo.getUserById(driverId);
});

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final c = math.cos;
  final a = 0.5 - c((lat2 - lat1) * p)/2 + 
        c(lat1 * p) * c(lat2 * p) * 
        (1 - c((lon2 - lon1) * p))/2;
  return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
}

class ActiveRideSheet extends ConsumerStatefulWidget {
  final Trip trip;

  const ActiveRideSheet({super.key, required this.trip});

  @override
  ConsumerState<ActiveRideSheet> createState() => _ActiveRideSheetState();
}

class _ActiveRideSheetState extends ConsumerState<ActiveRideSheet> {
  bool _isCollapsed = false;

  void _showCancelConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Cancel Booking?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.black87),
          ),
          content: Text(
            'Are you sure you want to cancel this booking and book another ride?',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'No, Keep It',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14.sp),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cancelling booking...')),
                );
                
                final success = await ref
                    .read(bookingRepositoryProvider)
                    .updateBookingStatus(widget.trip.id, 'cancelled');
                
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking cancelled. You can now make a new booking.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to cancel booking. Please try again.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                elevation: 0,
              ),
              child: Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final driverAsync = trip.driverId != null ? ref.watch(driverInfoProvider(trip.driverId!)) : const AsyncValue.loading();
    final trackingState = trip.driverId != null ? ref.watch(trackingStateProvider(trip.driverId!)) : null;
    final vehiclesAsync = ref.watch(allVehiclesProvider);

    final vehicle = vehiclesAsync.maybeWhen(
      data: (vehicles) {
        try {
          return vehicles.firstWhere((v) => v.id == trip.vehicleId);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    final driverName = driverAsync.maybeWhen(
      data: (user) => user?.name ?? 'Sergio Ramasis', // Fallback to mock if null
      orElse: () => 'Sergio Ramasis',
    );
    
    final driverPhone = driverAsync.maybeWhen(
      data: (user) => user?.phone,
      orElse: () => null,
    );

    // Calculate dynamic distance and ETA
    String distanceText = 'Calculating...';
    String timeText = 'Calculating...';

    final pickupLatLngList = parseLatLngFromString(trip.pickupLocation);
    if (pickupLatLngList != null && pickupLatLngList.length == 2 && trackingState?.position != null) {
      final pickupLat = pickupLatLngList[0];
      final pickupLng = pickupLatLngList[1];
      final driverLat = trackingState!.position!.latitude;
      final driverLng = trackingState.position!.longitude;

      final double distance = _calculateDistance(pickupLat, pickupLng, driverLat, driverLng);
      distanceText = '${distance.toStringAsFixed(1)} km away';
      
      final etaMinutes = (distance / 0.5).ceil();
      if (etaMinutes <= 0) {
        timeText = 'Arrived';
      } else if (etaMinutes == 1) {
        timeText = '1 min away';
      } else {
        timeText = '$etaMinutes mins away';
      }
    } else {
      distanceText = '3.5 km away';
      timeText = '5 mins away';
    }

    final String titleText;
    if (trip.status == TripStatus.arrived) {
      titleText = 'Your driver has arrived';
    } else if (trip.status == TripStatus.inProgress) {
      titleText = 'Trip in progress';
    } else {
      titleText = 'Your driver is on the way';
    }

    // Determine payment info
    final String paymentMethodText;
    final IconData paymentIcon;
    switch (trip.paymentGateway?.toLowerCase()) {
      case 'wallet':
        paymentMethodText = 'My Wallet';
        paymentIcon = Icons.account_balance_wallet_outlined;
        break;
      case 'cash':
        paymentMethodText = 'Cash';
        paymentIcon = Icons.payments_outlined;
        break;
      case 'paypal':
        paymentMethodText = 'PayPal';
        paymentIcon = Icons.payment;
        break;
      case 'stripe':
      default:
        paymentMethodText = 'Credit Card';
        paymentIcon = Icons.credit_card;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(
                    _isCollapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gold,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
              sizeCurve: Curves.easeInOut,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16.h),
                  Divider(color: Colors.grey[200], height: 1),
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Row(
                      children: [
                        Builder(builder: (context) {
                          final hasAvatar = driverAsync.value?.avatarUrl != null &&
                              driverAsync.value!.avatarUrl.isNotEmpty;
                          final initials = driverName.trim().isEmpty
                              ? 'D'
                              : driverName.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join();
                          if (hasAvatar) {
                            return Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(driverAsync.value!.avatarUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }
                          return CircleAvatar(
                            radius: 25.r,
                            backgroundColor: AppColors.gold,
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                              ),
                              if (vehicle != null) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  '${vehicle.color ?? "Black"} ${vehicle.name}',
                                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                ),
                              ],
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 12.sp, color: Colors.grey[600]),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      timeText,
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    child: Text('•', style: TextStyle(fontSize: 12.sp, color: Colors.grey[400])),
                                  ),
                                  Flexible(
                                    child: Text(
                                      distanceText,
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (vehicle != null && vehicle.imageUrl.isNotEmpty)
                          SizedBox(
                            width: 70.w,
                            height: 55.h,
                            child: Image.network(
                              vehicle.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car, size: 36.sp, color: Colors.grey),
                            ),
                          )
                        else
                          SizedBox(
                            width: 70.w,
                            height: 55.h,
                            child: Image.asset(
                              'assets/images/car_suv.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car, size: 36.sp, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[200], height: 1),
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment method', style: TextStyle(fontSize: 14.sp, color: Colors.grey[700])),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEA),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(paymentIcon, size: 16.sp, color: Colors.black87),
                                  SizedBox(width: 8.w),
                                  Text(paymentMethodText, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          trip.price ?? '\$0.00',
                          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (driverPhone != null && driverPhone.isNotEmpty) {
                                final cleanPhone = driverPhone.replaceAll(RegExp(r'[^\d+]'), '');
                                launchUrl(Uri.parse('tel:$cleanPhone'));
                              }
                            },
                            icon: Icon(Icons.phone, size: 18.sp, color: AppColors.gold),
                            label: Text(
                              'Call Driver',
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.gold),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50.h),
                              side: BorderSide(color: AppColors.gold, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push(
                                '/chat/${trip.id}',
                                extra: {'otherName': driverName},
                              );
                            },
                            icon: Icon(Icons.chat_bubble_outline, size: 18.sp, color: Colors.black87),
                            label: Text(
                              'Chat',
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50.h),
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 12.h),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCancelConfirmationDialog(context),
                        icon: Icon(Icons.cancel_outlined, size: 18.sp, color: Colors.red.shade700),
                        label: Text(
                          'Cancel & Book Again',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          elevation: 0,
                          side: BorderSide(color: Colors.red.shade100, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10.h),
          ],
        ),
      ),
    );
  }
}
