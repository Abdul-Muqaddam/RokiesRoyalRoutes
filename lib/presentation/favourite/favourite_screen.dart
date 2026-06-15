import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../profile/saved_locations_view_model.dart';
import '../../data/models/user_models.dart';

class FavouriteScreen extends ConsumerWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLocationsAsync = ref.watch(savedLocationsStreamProvider);
    const Color brandYellow = Color(0xFFDC423D);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),
            _buildTopAppBar(context),
            SizedBox(height: 15.h),
            Expanded(
              child: savedLocationsAsync.when(
                data: (locations) {
                  if (locations.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 10.h, bottom: 120.h),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      return _buildFavouriteCard(location);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: brandYellow)),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.menu, onTap: () => Scaffold.of(context).openDrawer()),
          Text(
            'Favourite',
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20.sp),
      ),
    );
  }

  Widget _buildFavouriteCard(LocationItem location) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDC423D).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: Colors.black87, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  location.address,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F), // Red remove icon background
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.remove, color: Colors.white, size: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80.r, color: Colors.grey[200]),
          SizedBox(height: 20.h),
          Text(
            'No Favourites Yet',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add your frequent destinations here.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
