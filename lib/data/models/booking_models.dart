
class UserBookingResponse {
  final int id;
  final String? title;
  final String? status;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? pickupDate;
  final String? pickupTime;
  final String? totalPrice;
  final String? currency;
  final String? timezone;
  final String? createdAt;

  UserBookingResponse({
    required this.id,
    this.title,
    this.status,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupDate,
    this.pickupTime,
    this.totalPrice,
    this.currency,
    this.timezone,
    this.createdAt,
  });

  factory UserBookingResponse.fromJson(Map<String, dynamic> json) {
    return UserBookingResponse(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: (json['vehicleName'] ?? json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      pickupLocation: (json['pickupLocation'] ?? json['pickup_location'] ?? '').toString(),
      dropoffLocation: (json['dropoffLocation'] ?? json['dropoff_location'] ?? '').toString(),
      pickupDate: (json['pickupDate'] ?? json['pickup_date'] ?? '').toString(),
      pickupTime: (json['pickupTime'] ?? json['pickup_time'] ?? '').toString(),
      totalPrice: (json['totalPrice'] ?? json['total_price'] ?? '').toString(),
      currency: (json['currency'] ?? 'CAD').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      createdAt: (json['bookingDate'] ?? json['created_at'] ?? '').toString(),
    );
  }
}

class UserBookingsWrapperDto {
  final bool success;
  final List<UserBookingResponse> bookings;

  UserBookingsWrapperDto({
    required this.success,
    required this.bookings,
  });

  factory UserBookingsWrapperDto.fromJson(Map<String, dynamic> json) {
    final bookingsList = json['bookings'] ?? json['data'] ?? [];
    return UserBookingsWrapperDto(
      success: json['success'] as bool? ?? false,
      bookings: (bookingsList as List<dynamic>)
              .map((e) => UserBookingResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

enum TripStatus { confirmed, pending, cancelled, past }

class Trip {
  final String id;
  final String title;
  final String dateTime;
  final TripStatus status;
  final String vehicleType;
  final String? pickupDate;
  final String? pickupTime;

  Trip({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.status,
    required this.vehicleType,
    this.pickupDate,
    this.pickupTime,
  });
}
