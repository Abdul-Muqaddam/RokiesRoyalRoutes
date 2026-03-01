import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'booking_view_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingViewModelProvider).value;
    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.navy, size: 24.w),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Booking Invoice',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: AppColors.navy, size: 22.w),
            onPressed: () {
              // Share logic
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  _InvoiceHeader(bookingId: state.bookingStatus?.bookingId),
                  SizedBox(height: 32.h),
                  _InvoiceSection(
                    title: 'RIDE INFO',
                    child: Column(
                      children: [
                        _InvoiceRow(label: 'Vehicle', value: state.selectedVehicle?.name ?? 'N/A'),
                        _InvoiceRow(label: 'Category', value: state.selectedVehicle?.category ?? 'N/A'),
                        _InvoiceRow(label: 'Date', value: '${state.selectedDate.day}/${state.selectedDate.month}/${state.selectedDate.year}'),
                        _InvoiceRow(label: 'Time', value: state.pickupTimeType == 'NOW' ? 'Now' : state.selectedTime),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _InvoiceSection(
                    title: 'ROUTE',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RoutePoint(label: 'From', value: state.pickupLocation, color: AppColors.gold),
                        SizedBox(height: 16.h),
                        _RoutePoint(label: 'To', value: state.destination, color: AppColors.navy),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _InvoiceSection(
                    title: 'CUSTOMER',
                    child: Column(
                      children: [
                        _InvoiceRow(label: 'Name', value: '${state.firstName} ${state.lastName}'),
                        _InvoiceRow(label: 'Email', value: state.email),
                        _InvoiceRow(label: 'Phone', value: state.phone),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  const Divider(height: 1),
                  SizedBox(height: 24.h),
                  _PriceRow(label: 'Subtotal', value: '${state.selectedVehicle?.currency} ${state.selectedVehicle?.price.toStringAsFixed(0)}'),
                  _PriceRow(label: 'Tax (0%)', value: '${state.selectedVehicle?.currency} 0'),
                  SizedBox(height: 12.h),
                  _PriceRow(
                    label: 'Total Amount',
                    value: '${state.selectedVehicle?.currency} ${state.selectedVehicle?.price.toStringAsFixed(0)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                elevation: 0,
              ),
              child: Text('Done', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  final int? bookingId;
  const _InvoiceHeader({this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INVOICE', style: TextStyle(color: AppColors.navy, fontSize: 24.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
            if (bookingId != null)
              Text('REF: #$bookingId', style: TextStyle(color: AppColors.gold, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12.r)),
          child: SvgPicture.asset('assets/icons/ic_car.svg', colorFilter: const ColorFilter.mode(AppColors.gold, BlendMode.srcIn), width: 24.w),
        ),
      ],
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _InvoiceSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
        SizedBox(height: 12.h),
        child,
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13.sp)),
          Text(value, style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13.sp)),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RoutePoint({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8.w, height: 8.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
              Text(value, style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _PriceRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? AppColors.navy : Colors.grey[600], fontSize: isTotal ? 16.sp : 14.sp, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isTotal ? AppColors.gold : AppColors.navy, fontSize: isTotal ? 20.sp : 14.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
