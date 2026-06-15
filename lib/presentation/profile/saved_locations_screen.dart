import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_models.dart';
import 'saved_locations_view_model.dart';
import 'location_dialogs.dart';

class SavedLocationsScreen extends ConsumerWidget {
  const SavedLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(savedLocationsViewModelProvider);
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
          'Saved Locations',
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
          Expanded(
            child: locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return _buildEmptyState(brandYellow);
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final place = locations[index];
                    return _buildLocationCard(context, ref, place, brandYellow);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildAddButton(context, ref, brandYellow),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, WidgetRef ref, LocationItem place, Color brandYellow) {
    IconData icon;
    final name = place.name.toLowerCase();
    if (name == 'home') {
      icon = Icons.home_outlined;
    } else if (name == 'work') {
      icon = Icons.work_outline;
    } else {
      icon = Icons.location_on_outlined;
    }

    final isFixed = name == 'home' || name == 'work';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: brandYellow.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: brandYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: brandYellow, size: 22.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 4.h),
                Text(
                  place.address,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showEditDialog(context, place),
                icon: Icon(Icons.edit_outlined, color: Colors.black26, size: 20.sp),
              ),
              if (!isFixed)
                IconButton(
                  onPressed: () => ref.read(savedLocationsViewModelProvider.notifier).deleteCustomLocation(place),
                  icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.4), size: 20.sp),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color brandYellow) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 64.sp, color: brandYellow.withOpacity(0.2)),
          SizedBox(height: 16.h),
          Text(
            'No saved locations yet',
            style: TextStyle(fontSize: 16.sp, color: Colors.black26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, Color brandYellow) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          onPressed: () => _showEditDialog(context, null),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandYellow,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: Text('Add New Location', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, LocationItem? place) {
    showDialog(
      context: context,
      builder: (context) => AddPlaceDialog(initialPlace: place),
    );
  }
}
