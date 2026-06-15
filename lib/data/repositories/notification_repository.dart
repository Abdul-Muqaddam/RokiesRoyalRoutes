import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_models.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  /// Stream of notifications for the currently logged-in user.
  /// Listens to Supabase Realtime for instant delivery.
  Stream<List<NotificationDto>> streamNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    final controller = StreamController<List<NotificationDto>>();

    Future<void> fetch() async {
      try {
        final data = await _supabase
            .from('notifications')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        final list = (data as List)
            .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
            .toList();

        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetch();

    // Listen for INSERT/UPDATE in real-time
    final channel = _supabase
        .channel('notifications-stream-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => fetch(),
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark ALL notifications as read for the current user.
  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  /// Insert a notification (call this from booking/payment logic).
  Future<void> insert({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
    });
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationDto>>((ref) {
  return ref.watch(notificationRepositoryProvider).streamNotifications();
});

/// Unread count — used for the badge on the bell icon.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsStreamProvider).maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
