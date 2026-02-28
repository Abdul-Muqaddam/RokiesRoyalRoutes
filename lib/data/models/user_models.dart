class UserDto {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final int totalTrips;
  final String totalSpent;

  UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl = '',
    this.totalTrips = 0,
    this.totalSpent = '\$0.00',
  });

  String get displayName => name.isNotEmpty ? name : 'User';

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['displayName'] ?? json['name'] ?? json['first_name'] ?? json['firstName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      avatarUrl: (json['avatar'] ?? json['avatar_url'] ?? json['profile_pic'] ?? '').toString(),
      totalTrips: json['total_trips'] is int ? json['total_trips'] as int : int.tryParse(json['total_trips']?.toString() ?? '0') ?? 0,
      totalSpent: (json['total_spent'] ?? '\$0.00').toString(),
    );
  }
}

class UserProfileResponse {
  final bool success;
  final String message;
  final UserDto? user;

  UserProfileResponse({required this.success, required this.message, this.user});

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      user: json['user'] != null 
          ? UserDto.fromJson(json['user']) 
          : (json['data'] != null ? UserDto.fromJson(json['data']) : null),
    );
  }
}

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    };
  }
}

class ChangePasswordResponse {
  final bool success;
  final String message;

  ChangePasswordResponse({required this.success, required this.message});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
