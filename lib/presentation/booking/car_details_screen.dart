import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/vehicle_models.dart';
import 'booking_view_model.dart';

class CarDetailsScreen extends ConsumerWidget {
  final Vehicle vehicle;
  const CarDetailsScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color brandYellow = Color(0xFFDC423D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20.sp, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Back',
          style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
        titleSpacing: -10,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                vehicle.name,
                style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.star, color: brandYellow, size: 20.sp),
                  SizedBox(width: 4.w),
                  Text(
                    '4.9',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black38),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '(531 reviews)',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black26),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (vehicle.imageUrl.isNotEmpty)
                      Image.network(
                        vehicle.imageUrl,
                        height: 180.h,
                        fit: BoxFit.contain,
                      )
                    else
                      Icon(Icons.directions_car, size: 100.sp, color: Colors.grey[200]),
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 24.sp, color: Colors.black26),
                        onPressed: () {},
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: 24.sp, color: Colors.black26),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                'Specifications',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSpecTile(Icons.battery_charging_full, 'Max. power', vehicle.maxPower ?? 'N/A'),
                  _buildSpecTile(Icons.local_gas_station, 'Fuel', vehicle.fuelEfficiency ?? 'N/A'),
                  _buildSpecTile(Icons.speed, 'Max. speed', vehicle.maxSpeed ?? 'N/A'),
                  _buildSpecTile(Icons.timer, '0-60mph', vehicle.acceleration ?? 'N/A'),
                ],
              ),
              SizedBox(height: 40.h),
              Text(
                'Car features',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 16.h),
              _buildFeatureRow('Model', vehicle.model.isNotEmpty ? vehicle.model : 'GT5000'),
              _buildFeatureRow('Capacity', '${vehicle.passengers} seats'),
              _buildFeatureRow('Color', vehicle.color ?? 'Black'),
              _buildFeatureRow('Fuel type', vehicle.fuelType ?? vehicle.type),
              _buildFeatureRow('Gear type', vehicle.gearType ?? 'Automatic'),
              SizedBox(height: 120.h), // Extra space for sticky buttons
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 20.h, bottom: 34.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(bookingViewModelProvider.notifier).selectVehicle(vehicle);
                  ref.read(bookingViewModelProvider.notifier).setPickupTimeType('SCHEDULE');
                  ref.read(bookingViewModelProvider.notifier).updateStep(0);
                  context.push('/booking');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: brandYellow, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  'Book later',
                  style: TextStyle(color: brandYellow, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(bookingViewModelProvider.notifier).selectVehicle(vehicle);
                  ref.read(bookingViewModelProvider.notifier).setPickupTimeType('NOW');
                  ref.read(bookingViewModelProvider.notifier).updateStep(0);
                  context.push('/booking');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  'Ride Now',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecTile(IconData icon, String label, String value) {
    return Container(
      width: 75.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFDC423D).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black54, size: 20.sp),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.black38), textAlign: TextAlign.center),
          Text(value, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEA).withOpacity(0.3),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFDC423D).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black54, fontWeight: FontWeight.w500)),
          SizedBox(width: 20.w),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
