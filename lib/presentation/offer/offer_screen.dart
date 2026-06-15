import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);

    final List<Map<String, dynamic>> offers = [
      {
        'title': 'Discount 15% off',
        'subtitle': 'Special Promo valid for Black Friday',
        'color': const Color(0xFFD32F2F),
      },
      {
        'title': 'Special 5% off',
        'subtitle': 'Special Weekend deal promo',
        'color': const Color(0xFF388E3C),
      },
      {
        'title': 'Cashback 15%',
        'subtitle': 'Special Promo valid for today',
        'color': const Color(0xFF1976D2),
      },
      {
        'title': 'Special 15% off',
        'subtitle': 'Special Promo valid for Black Friday',
        'color': const Color(0xFFD32F2F),
      },
      {
        'title': 'Discount 15% off',
        'subtitle': 'Special Promo valid for Black Friday',
        'color': const Color(0xFF7B1FA2),
      },
      {
        'title': 'Discount 15% off',
        'subtitle': 'Special Promo valid for Black Friday',
        'color': const Color(0xFF388E3C),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),
            _buildTopAppBar(context),
            SizedBox(height: 15.h),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h, bottom: 120.h),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return _buildOfferCard(context, offer);
                },
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
            'Special Offer',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
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

  Widget _buildOfferCard(BuildContext context, Map<String, dynamic> offer) {
    const Color brandYellow = Color(0xFFDC423D);
    final Color iconColor = offer['color'];

    return GestureDetector(
      onTap: () => _showOfferDetails(context, offer),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: brandYellow.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54.r,
              height: 54.r,
              decoration: BoxDecoration(
                color: brandYellow.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: iconColor, size: 28.sp),
                    Positioned(
                      bottom: 6.r,
                      child: Text(
                        '%',
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['title'],
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    offer['subtitle'],
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferDetails(BuildContext context, Map<String, dynamic> offer) {
    const Color brandYellow = Color(0xFFDC423D);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 0.85.sh,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 24.w),
                  Text(
                    'Special Offer',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 20.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  children: [
                    Container(
                      width: 120.r,
                      height: 120.r,
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: brandYellow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/879/879859.png', // Yellow tag icon
                        errorBuilder: (_, __, ___) => Icon(Icons.confirmation_number, size: 60.r, color: brandYellow),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      offer['title'],
                      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      offer['subtitle'],
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: brandYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DISC35',
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(width: 12.w),
                          Icon(Icons.copy, size: 18.sp, color: Colors.black54),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 2.w),
                            height: 1.h,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Terms and Conditions',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildTermsPoint('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
                    _buildTermsPoint('Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'),
                    _buildTermsPoint('Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.'),
                    SizedBox(height: 30.h),
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandYellow,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        child: Text('Use Promo', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Container(width: 4.r, height: 4.r, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
