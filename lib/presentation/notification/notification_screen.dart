import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/notification_models.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  static const Color _brandYellow = Color(0xFFDC423D);
  static const Color _bgColor = Color(0xFFF8F8F8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),
            _buildTopBar(context, ref, notificationsAsync),
            SizedBox(height: 8.h),
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) return _buildEmptyState();
                  final grouped = _groupByDate(notifications);
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final group = grouped[index];
                      return _buildGroup(context, ref, group);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: _brandYellow)),
                error: (e, _) => _buildErrorState(e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, AsyncValue<List<NotificationDto>> notificationsAsync) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _buildCircleButton(Icons.arrow_back, onTap: () => context.pop()),
          Expanded(
            child: Center(
              child: Text(
                'Notifications',
                style: TextStyle(color: Colors.black, fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // "Mark all read" button — only shows when there are unread
          notificationsAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return SizedBox(width: 42.w);
              return GestureDetector(
                onTap: () => ref.read(notificationRepositoryProvider).markAllAsRead(),
                child: Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEA),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(Icons.done_all, color: _brandYellow, size: 20.sp),
                ),
              );
            },
            orElse: () => SizedBox(width: 42.w),
          ),
        ],
      ),
    );
  }

  // Group notifications by their dateLabel (Today / Yesterday / Date)
  List<Map<String, dynamic>> _groupByDate(List<NotificationDto> notifications) {
    final Map<String, List<NotificationDto>> map = {};
    for (final n in notifications) {
      map.putIfAbsent(n.dateLabel, () => []).add(n);
    }
    return map.entries.map((e) => {'date': e.key, 'items': e.value}).toList();
  }

  Widget _buildGroup(BuildContext context, WidgetRef ref, Map<String, dynamic> group) {
    final items = group['items'] as List<NotificationDto>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Text(
            group['date'] as String,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        ...items.map((item) => _buildCard(context, ref, item)),
      ],
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, NotificationDto item) {
    return GestureDetector(
      onTap: () => ref.read(notificationRepositoryProvider).markAsRead(item.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFFFEBEA),
          borderRadius: BorderRadius.circular(16.r),
          border: item.isRead
              ? null
              : Border.all(color: _brandYellow.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: item.isRead ? 0.02 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: item.isRead ? Colors.black87 : Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: _brandYellow, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(color: _brandYellow, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.body,
                    style: TextStyle(fontSize: 13.sp, color: Colors.black38, height: 1.4),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _formatTime(item.createdAt),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20.sp),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(color: const Color(0xFFFFEBEA), shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 48.w, color: _brandYellow),
          ),
          SizedBox(height: 20.h),
          Text('No notifications yet', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
          SizedBox(height: 8.h),
          Text("We'll notify you when something arrives", style: TextStyle(fontSize: 13.sp, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48.w, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text('Could not load notifications', style: TextStyle(fontSize: 16.sp, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}
