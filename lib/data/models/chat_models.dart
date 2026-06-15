class ChatMessage {
  final String id;
  final String tripId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'sender_id': senderId,
        'message': message,
      };
}
