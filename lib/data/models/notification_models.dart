import 'package:flutter/material.dart';

class NotificationDto {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'booking', 'payment', 'discount', 'wallet', 'general'
  final bool isRead;
  final DateTime createdAt;

  NotificationDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: json['title'].toString(),
      body: json['body'].toString(),
      type: json['type']?.toString() ?? 'general',
      isRead: json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
    );
  }

  NotificationDto copyWith({bool? isRead}) {
    return NotificationDto(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  IconData get icon {
    switch (type) {
      case 'payment':  return Icons.payment;
      case 'booking':  return Icons.directions_car;
      case 'discount': return Icons.percent;
      case 'wallet':   return Icons.account_balance_wallet;
      case 'driver':   return Icons.person_pin;
      default:         return Icons.notifications;
    }
  }

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return '${_monthName(createdAt.month)} ${createdAt.day}, ${createdAt.year}';
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
