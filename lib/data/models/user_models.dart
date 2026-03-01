class UserDto {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final int totalTrips;
  final String totalSpent;
  final String firstName;
  final String lastName;
  final String nickname;
  final String bio;
  final String website;

  UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl = '',
    this.totalTrips = 0,
    this.totalSpent = '\$0.00',
    this.firstName = '',
    this.lastName = '',
    this.nickname = '',
    this.bio = '',
    this.website = '',
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
      firstName: (json['first_name'] ?? json['firstName'] ?? '').toString(),
      lastName: (json['last_name'] ?? json['lastName'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      bio: (json['description'] ?? json['bio'] ?? '').toString(),
      website: (json['url'] ?? json['website'] ?? '').toString(),
    );
  }
}

class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? name; // Display name
  final String? nickname;
  final String? phone;
  final String? website;
  final String? bio;

  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.name,
    this.nickname,
    this.phone,
    this.website,
    this.bio,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (name != null) 'name': name,
      if (nickname != null) 'nickname': nickname,
      if (phone != null) 'phone': phone,
      if (website != null) 'url': website,
      if (bio != null) 'description': bio,
    };
  }
}

class LocationItem {
  final String name;
  final String address;

  LocationItem({required this.name, required this.address});

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }
}

class SavedLocationsResponse {
  final String? home;
  final String? work;
  final List<CustomPlace>? custom;

  SavedLocationsResponse({this.home, this.work, this.custom});

  factory SavedLocationsResponse.fromJson(Map<String, dynamic> json) {
    return SavedLocationsResponse(
      home: json['home']?.toString(),
      work: json['work']?.toString(),
      custom: (json['custom'] as List?)
          ?.map((e) => CustomPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CustomPlace {
  final String name;
  final String address;

  CustomPlace({required this.name, required this.address});

  factory CustomPlace.fromJson(Map<String, dynamic> json) {
    return CustomPlace(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
  };
}

class UpdateLocationsRequest {
  final String? home;
  final String? work;
  final List<CustomPlace>? custom;

  UpdateLocationsRequest({this.home, this.work, this.custom});

  Map<String, dynamic> toJson() {
    return {
      'home': home,
      'work': work,
      'custom': custom?.map((e) => e.toJson()).toList(),
    };
  }
}

class AutocompleteResponse {
  final List<Prediction> predictions;
  final String status;

  AutocompleteResponse({required this.predictions, required this.status});

  factory AutocompleteResponse.fromJson(Map<String, dynamic> json) {
    return AutocompleteResponse(
      predictions: (json['predictions'] as List? ?? [])
          .map((e) => Prediction.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status']?.toString() ?? '',
    );
  }
}

class Prediction {
  final String description;
  final String placeId;
  final StructuredFormatting structuredFormatting;

  Prediction({
    required this.description,
    required this.placeId,
    required this.structuredFormatting,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      description: json['description']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      structuredFormatting: StructuredFormatting.fromJson(
        json['structured_formatting'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class StructuredFormatting {
  final String mainText;
  final String? secondaryText;

  StructuredFormatting({required this.mainText, this.secondaryText});

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text']?.toString() ?? '',
      secondaryText: json['secondary_text']?.toString(),
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
