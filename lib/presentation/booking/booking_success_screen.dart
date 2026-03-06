import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'booking_view_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingViewModelProvider).value;
    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8.r)),
                child: SvgPicture.asset('assets/icons/ic_car.svg', colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn), width: 18.w),
              ),
              SizedBox(width: 12.w),
              Text('Rockies Royal Routes', style: TextStyle(color: Theme.of(context).textTheme.titleSmall?.color, fontWeight: FontWeight.bold, fontSize: 16.sp)),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _SuccessHeader(firstName: state.firstName, bookingId: state.bookingStatus?.bookingId),
              SizedBox(height: 16.h),
              _RideDetailsCard(state: state),
              SizedBox(height: 16.h),
              _CustomerInfoCard(state: state),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: Text('Back to Home', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => context.push('/invoice'),
                child: Text('View Invoice', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => context.go('/trips'),
                child: Text('View My Trips', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 14.sp)),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  final String firstName;
  final int? bookingId;
  const _SuccessHeader({required this.firstName, this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: Center(
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
                child: Icon(Icons.check, color: AppColors.white, size: 32.w),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            firstName.isNotEmpty ? 'Congratulations, $firstName!' : 'Ride Booked Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).textTheme.headlineSmall?.color, fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your booking is confirmed.\nYour chauffeur will be ready for your trip.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8), fontSize: 14.sp, height: 1.5),
          ),
          if (bookingId != null) ...[
            SizedBox(height: 16.h),
            Text(
              'Ref: #$bookingId',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ],
        ],
      ),
    );
  }
}

class _RideDetailsCard extends StatelessWidget {
  final BookingState state;
  const _RideDetailsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RIDE DETAILS', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(width: 8.w),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        state.selectedVehicle?.name ?? 'Vehicle', 
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11.sp, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _RouteIndicator(pickup: state.pickupLocation, destination: state.destination),
          SizedBox(height: 24.h),
          const Divider(),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Distance', value: state.distance ?? '—'),
              _VerticalDivider(),
              _StatItem(label: 'Est. Time', value: state.duration ?? '—'),
              _VerticalDivider(),
              _StatItem(label: 'Price', value: '${state.selectedVehicle?.currency} ${state.selectedVehicle?.price.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteIndicator extends StatelessWidget {
  final String pickup;
  final String destination;
  const _RouteIndicator({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            SizedBox(height: 10.h), // Top padding to center first dot with Pickup text
            Container(width: 14.w, height: 14.w, decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 3), shape: BoxShape.circle, color: AppColors.white)),
            Container(width: 2.w, height: 42.h, color: Colors.grey[200]),
            Container(width: 14.w, height: 14.w, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
          ],
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pickup', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10.sp)),
              Text(pickup, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 20.h),
              Text('Drop-off', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10.sp)),
              Text(destination, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10.sp)),
        SizedBox(height: 4.h),
        Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 13.sp)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32.h, color: Colors.grey[200]);
}

class _CustomerInfoCard extends StatelessWidget {
  final BookingState state;
  const _CustomerInfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CUSTOMER INFORMATION', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
          SizedBox(height: 24.h),
          _InfoRow(icon: Icons.person, label: 'Name', value: '${state.firstName} ${state.lastName}'),
          SizedBox(height: 16.h),
          _InfoRow(icon: Icons.email, label: 'Email', value: state.email),
          SizedBox(height: 16.h),
          _InfoRow(icon: Icons.phone, label: 'Phone', value: state.phone),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10.sp)),
            Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 13.sp)),
          ],
        ),
      ],
    );
  }
}
