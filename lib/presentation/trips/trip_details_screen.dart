import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_models.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final primaryGold = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 1. The Architectural Anchor Line
          Positioned(
            left: 32.w,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    primaryGold.withOpacity(0.3),
                    primaryGold.withOpacity(0.5),
                    primaryGold.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Custom App Bar
                Padding(
                  padding: EdgeInsets.only(left: 16.w, top: 16.h),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withOpacity(0.5), size: 20.sp),
                    onPressed: () => context.pop(),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(left: 48.w, right: 24.w, top: 20.h, bottom: 40.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3. Editorial Header
                        _AnimateIn(
                          delay: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VOYAGE',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                  color: primaryGold,
                                  letterSpacing: 8,
                                ),
                              ),
                              Text(
                                'MANIFEST',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 50.h),

                        // 4. Booking Stamp
                        _AnimateIn(
                          delay: 200,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('REFERENCE', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8.sp, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(trip.reference?.toUpperCase() ?? 'N/A', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w100)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16.w),
                              _StatusBadge(status: trip.status),
                            ],
                          ),
                        ),

                        SizedBox(height: 50.h),

                        // 5. Ride Manifest Details
                        _AnimateIn(
                          delay: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RIDE SPECIFICATIONS', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 3)),
                              SizedBox(height: 24.h),
                              _DetailRow(label: 'VEHICLE', value: trip.title),
                              _DetailRow(label: 'CATEGORY', value: trip.vehicleType),
                              _DetailRow(label: 'SCHEDULE', value: trip.dateTime),
                            ],
                          ),
                        ),

                        SizedBox(height: 50.h),

                        // 6. Journey Path
                        _AnimateIn(
                          delay: 600,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('JOURNEY PATH', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 3)),
                              SizedBox(height: 24.h),
                              _buildLocationThread(trip.pickupLocation, trip.dropoffLocation, primaryGold),
                            ],
                          ),
                        ),

                        if (trip.price != null) ...[
                          SizedBox(height: 60.h),
                          _AnimateIn(
                            delay: 800,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(height: 1.h, width: 40.w, color: primaryGold.withOpacity(0.3)),
                                SizedBox(height: 24.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(trip.price!, style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w100)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 60.h),
                        
                        // 7. Interactive Actions
                        _AnimateIn(
                          delay: 1000,
                          child: Row(
                            children: [
                              if (trip.status == TripStatus.confirmed || trip.status == TripStatus.pending || trip.status == TripStatus.inProgress || trip.status == TripStatus.arrived) ...[
                                Expanded(
                                  flex: 3,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Implementation for driver tracking
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 18.h),
                                      decoration: BoxDecoration(
                                        color: primaryGold,
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'TRACK JOURNEY',
                                          style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.w900, letterSpacing: 1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (trip.driverId != null) ...[
                                  SizedBox(width: 12.w),
                                  GestureDetector(
                                    onTap: () {
                                      context.push(
                                        '/chat/${trip.id}',
                                        extra: {'otherName': 'Driver'},
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(4.r),
                                        border: Border.all(color: primaryGold.withOpacity(0.5), width: 1),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: primaryGold,
                                          size: 16.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationThread(String? pickup, String? dropoff, Color primaryGold) {
    return Column(
      children: [
        _buildLocationRow('FROM', pickup ?? 'N/A', primaryGold, isStart: true),
        Padding(
          padding: EdgeInsets.only(left: 3.w),
          child: Container(
            height: 40.h,
            width: 1.w,
            color: primaryGold.withOpacity(0.2),
          ),
        ),
        _buildLocationRow('TO', dropoff ?? 'N/A', primaryGold, isStart: false),
      ],
    );
  }

  Widget _buildLocationRow(String label, String location, Color primaryGold, {required bool isStart}) {
    return Row(
      children: [
        Container(
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(
            color: isStart ? primaryGold : Colors.transparent,
            border: Border.all(color: primaryGold, width: 1),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 7.sp, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text(
                location.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(isStart ? 0.7 : 0.4),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: Colors.white.withOpacity(0.2), 
              fontSize: 9.sp, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 2
            )
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: Colors.white, 
                fontSize: 11.sp, 
                fontWeight: FontWeight.w100, 
                letterSpacing: 1
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
      case TripStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        break;
      case TripStatus.pending:
        color = AppColors.gold;
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
      case TripStatus.arrived:
        color = Colors.teal;
        text = 'Driver Arrived';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(2.r),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }
}

class _AnimateIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimateIn({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
