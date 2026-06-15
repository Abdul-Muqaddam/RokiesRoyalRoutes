import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<bool> showLocationPermissionSheet(BuildContext context) async {
  return await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const LocationPermissionSheet(),
  ) ?? false;
}

class LocationPermissionSheet extends StatelessWidget {
  const LocationPermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 30.h),
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              color: brandYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: brandYellow, size: 40.r),
          ),
          SizedBox(height: 24.h),
          Text(
            'Enable Location Services',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'We need your location to show you nearby drivers and calculate accurate trip distances.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandYellow,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 54.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
            child: Text(
              'Allow Access',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              minimumSize: Size(double.infinity, 54.h),
            ),
            child: Text(
              'Maybe Later',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500], fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}
