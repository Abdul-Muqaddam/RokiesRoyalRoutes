import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/models/vehicle_models.dart';
import 'booking_view_model.dart';

class AvailableCarsScreen extends ConsumerWidget {
  const AvailableCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color brandYellow = Color(0xFFDC423D);
    final vehiclesAsync = ref.watch(allVehiclesProvider);

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
      body: vehiclesAsync.when(
        data: (vehicles) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available cars for ride',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${vehicles.length} cars found',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black38),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  return _buildCarCard(context, ref, vehicles[index], brandYellow);
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: brandYellow)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, WidgetRef ref, Vehicle vehicle, Color brandYellow) {
    return InkWell(
      onTap: () => context.push('/car-details', extra: vehicle),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: brandYellow.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Automatic  |  ${vehicle.passengers} seats  |  ${vehicle.type}',
                        style: TextStyle(fontSize: 12.sp, color: Colors.black38),
                      ),
                    ],
                  ),
                ),
                if (vehicle.imageUrl.isNotEmpty)
                  Image.network(
                    vehicle.imageUrl,
                    width: 120.w,
                    height: 60.h,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${vehicle.currency} ${vehicle.price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: brandYellow),
                ),
                Text(
                  'View Details',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: brandYellow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120.w,
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(Icons.directions_car, color: Colors.grey[300], size: 30.sp),
    );
  }
}

