import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/booking_models.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/user_repository_impl.dart';

/// Provider to fetch a single trip by ID.
final chatTripProvider = FutureProvider.autoDispose.family<Trip?, String>((ref, tripId) async {
  final supabase = Supabase.instance.client;
  final data = await supabase.from('bookings').select().eq('id', tripId).maybeSingle();
  if (data == null) return null;

  final statusStr = data['status'] ?? 'pending';
  TripStatus status;
  switch (statusStr.toLowerCase()) {
    case 'confirmed':
      status = TripStatus.confirmed;
      break;
    case 'cancelled':
      status = TripStatus.cancelled;
      break;
    case 'in_progress':
      status = TripStatus.inProgress;
      break;
    case 'arrived':
      status = TripStatus.arrived;
      break;
    case 'past':
    case 'completed':
      status = TripStatus.past;
      break;
    default:
      status = TripStatus.pending;
      break;
  }

  return Trip(
    id: data['id'].toString(),
    title: '${data['pickup_location']} to ${data['dropoff_location']}',
    dateTime: '${data['pickup_date']} at ${data['pickup_time']}',
    status: status,
    vehicleType: 'Executive Sedan',
    pickupDate: data['pickup_date'],
    pickupTime: data['pickup_time'],
    dropoffLocation: data['dropoff_location'],
    pickupLocation: data['pickup_location'],
    price: '${data['currency'] ?? 'CAD'} ${data['total_price'] ?? '0.00'}',
    reference: '#${data['id'].toString().substring(0, 8)}',
    userId: data['user_id']?.toString(),
    driverId: data['driver_id']?.toString(),
    paymentGateway: data['payment_gateway']?.toString(),
    vehicleId: data['vehicle_id']?.toString(),
  );
});

/// Provider to fetch other participant profile details.
final chatParticipantProvider = FutureProvider.autoDispose.family<UserDto?, String>((ref, userId) async {
  return ref.watch(userRepositoryProvider).getUserById(userId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String otherName;

  const ChatScreen({
    super.key,
    required this.tripId,
    required this.otherName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  static const Color brandYellow = Color(0xFFDC423D);
  static const Color lightYellow = Color(0xFFFFEBEA);

  /// Resolved display name of the current user (used in push notification title).
  String _currentUserDisplayName = 'Someone';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      _messageController.clear();
      await ref.read(chatRepositoryProvider).sendMessage(
            tripId: widget.tripId,
            message: text,
            senderName: _currentUserDisplayName,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(chatTripProvider(widget.tripId));

    // Resolve and cache the current user's display name for notifications
    tripAsync.whenData((trip) {
      if (trip == null) return;
      final currentUserId = ref.read(chatRepositoryProvider).currentUserId;
      final myUserId = currentUserId == trip.userId ? trip.userId : trip.driverId;
      if (myUserId != null) {
        ref.watch(chatParticipantProvider(myUserId)).whenData((user) {
          if (user?.name != null && user!.name.isNotEmpty) {
            _currentUserDisplayName = user.name;
          }
        });
      }
    });

    // Resolve participant name & role
    String participantName = widget.otherName;
    String participantRole = 'Chat';

    tripAsync.whenData((trip) {
      if (trip == null) return;
      final currentUserId = ref.read(chatRepositoryProvider).currentUserId;
      final otherUserId = currentUserId == trip.userId ? trip.driverId : trip.userId;
      participantRole = currentUserId == trip.userId ? 'Driver' : 'Passenger';
      if (otherUserId != null) {
        final participantAsync = ref.watch(chatParticipantProvider(otherUserId));
        participantAsync.whenData((user) {
          participantName = user?.name ?? widget.otherName;
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
        title: Column(
          children: [
            Text(
              participantName,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              participantRole,
              style: TextStyle(
                color: brandYellow,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Divider ────────────────────────────────────────────────
          Container(
            height: 1.h,
            color: Colors.grey.withOpacity(0.1),
          ),
          
          // ── Messages ───────────────────────────────────────────────
          Expanded(
            child: ref.watch(chatMessagesProvider(widget.tripId)).when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return _buildEmptyState();
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    final currentUserId = ref.watch(chatRepositoryProvider).currentUserId;

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUserId;
                        return _buildMessageRow(msg, isMe);
                      },
                    );
                  },
                  error: (error, _) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Text(
                        'Error loading messages: $error',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: brandYellow,
                    ),
                  ),
                ),
          ),

          // ── Input Bar ──────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.grey.withOpacity(0.3),
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message Bubble ────────────────────────────────────────────────────────

  Widget _buildMessageRow(ChatMessage msg, bool isMe) {
    final timeStr = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: 0.7.sw),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isMe ? brandYellow : lightYellow,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                    bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                  ),
                  border: isMe ? null : Border.all(
                    color: brandYellow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  msg.message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              timeStr,
              style: TextStyle(
                color: Colors.black26,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14.sp,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.black26,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48.h,
              width: 48.h,
              decoration: BoxDecoration(
                color: _isSending ? brandYellow.withOpacity(0.5) : brandYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!_isSending)
                    BoxShadow(
                      color: brandYellow.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Center(
                child: _isSending
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
