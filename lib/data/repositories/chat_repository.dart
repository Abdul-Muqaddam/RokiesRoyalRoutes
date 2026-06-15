import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';
import '../../core/services/push_notification_service.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Real-time stream of messages for a given trip.
  Stream<List<ChatMessage>> streamMessages(String tripId) {
    final controller = StreamController<List<ChatMessage>>();

    Future<void> fetch() async {
      try {
        final data = await _supabase
            .from('trip_messages')
            .select()
            .eq('trip_id', tripId)
            .order('created_at', ascending: true);

        final list = (data as List)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();

        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetch();

    final channel = _supabase
        .channel('trip-chat-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'trip_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
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

  /// Send a message and notify the other participant (driver → user or user → driver).
  Future<void> sendMessage({
    required String tripId,
    required String message,
    String? senderName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Insert the message
    await _supabase.from('trip_messages').insert({
      'trip_id': tripId,
      'sender_id': user.id,
      'message': message.trim(),
    });

    // 2. Fire push notification to the other participant — don't await so UI stays snappy
    _sendChatNotification(
      tripId: tripId,
      senderId: user.id,
      senderName: senderName ?? 'Someone',
      message: message.trim(),
    );
  }

  /// Resolves the recipient from the booking and dispatches the push notification.
  Future<void> _sendChatNotification({
    required String tripId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    try {
      // Fetch the booking to find the other participant
      final booking = await _supabase
          .from('bookings')
          .select('user_id, driver_id')
          .eq('id', tripId)
          .maybeSingle();

      if (booking == null) return;

      final userId = booking['user_id']?.toString();
      final driverId = booking['driver_id']?.toString();

      // Determine who the recipient is
      final String? recipientId;
      if (senderId == userId) {
        // User sent the message → notify the driver
        recipientId = driverId;
      } else {
        // Driver sent the message → notify the user
        recipientId = userId;
      }

      if (recipientId == null || recipientId.isEmpty) {
        debugPrint('⚠️ Chat notification skipped: no recipient found for trip $tripId');
        return;
      }

      // Send the push notification
      await PushNotificationService().sendPushNotification(
        recipientUserId: recipientId,
        title: '💬 New Message from $senderName',
        body: message.length > 100 ? '${message.substring(0, 97)}...' : message,
      );

      debugPrint('✅ Chat push notification sent to recipient: $recipientId');
    } catch (e) {
      debugPrint('❌ Failed to send chat push notification: $e');
    }
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, tripId) {
  return ref.watch(chatRepositoryProvider).streamMessages(tripId);
});

