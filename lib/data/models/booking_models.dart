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
  final String? paymentMethod;
  final String? paymentStatus;

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
    this.paymentMethod,
    this.paymentStatus,
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
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
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
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? price;
  final String? reference;

  Trip({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.status,
    required this.vehicleType,
    this.pickupDate,
    this.pickupTime,
    this.pickupLocation,
    this.dropoffLocation,
    this.price,
    this.reference,
  });
}

class BookingRequest {
  final int vehicleId;
  final String pickupLocation;
  final String dropoffLocation;
  final String pickupDate;
  final String pickupTime;
  final int passengers;
  final int luggage;
  final String paymentGateway;
  final CustomerInfoDto customerInfo;
  final double? totalPrice;
  final String? currency;
  final String? timezone;

  BookingRequest({
    required this.vehicleId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupDate,
    required this.pickupTime,
    required this.passengers,
    required this.luggage,
    required this.paymentGateway,
    required this.customerInfo,
    this.totalPrice,
    this.currency,
    this.timezone,
  });

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    'pickup_location': pickupLocation,
    'dropoff_location': dropoffLocation,
    'pickup_date': pickupDate,
    'pickup_time': pickupTime,
    'passengers': passengers,
    'luggage': luggage,
    'payment_gateway': paymentGateway,
    'customer_info': customerInfo.toJson(),
    if (totalPrice != null) 'total_price': totalPrice,
    if (currency != null) 'currency': currency,
    if (timezone != null) 'timezone': timezone,
  };
}

class CustomerInfoDto {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? additionalNote;

  CustomerInfoDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.additionalNote,
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    if (additionalNote != null) 'additional_note': additionalNote,
  };
}

class BookingResponse {
  final bool success;
  final int? bookingId;
  final String message;
  final String? paymentGateway;
  final bool? requiresPayment;
  final String? code;

  BookingResponse({
    required this.success,
    this.bookingId,
    required this.message,
    this.paymentGateway,
    this.requiresPayment,
    this.code,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      success: json['success'] as bool? ?? false,
      bookingId: json['booking_id'] as int?,
      message: json['message'] as String? ?? '',
      paymentGateway: json['payment_gateway'] as String?,
      requiresPayment: json['requires_payment'] as bool?,
      code: json['code'] as String?,
    );
  }
}

class DistanceMatrixResponse {
  final List<DistanceMatrixRow> rows;
  final String status;

  DistanceMatrixResponse({required this.rows, required this.status});

  factory DistanceMatrixResponse.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixResponse(
      rows: (json['rows'] as List? ?? [])
          .map((e) => DistanceMatrixRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? '',
    );
  }
}

class DistanceMatrixRow {
  final List<DistanceMatrixElement> elements;

  DistanceMatrixRow({required this.elements});

  factory DistanceMatrixRow.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixRow(
      elements: (json['elements'] as List? ?? [])
          .map((e) => DistanceMatrixElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DistanceMatrixElement {
  final DistanceMatrixValue? distance;
  final DistanceMatrixValue? duration;
  final String status;

  DistanceMatrixElement({this.distance, this.duration, required this.status});

  factory DistanceMatrixElement.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixElement(
      distance: json['distance'] != null ? DistanceMatrixValue.fromJson(json['distance']) : null,
      duration: json['duration'] != null ? DistanceMatrixValue.fromJson(json['duration']) : null,
      status: json['status'] as String? ?? '',
    );
  }
}

class DistanceMatrixValue {
  final String text;
  final int value;

  DistanceMatrixValue({required this.text, required this.value});

  factory DistanceMatrixValue.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixValue(
      text: json['text'] as String? ?? '',
      value: json['value'] as int? ?? 0,
    );
  }
}

class PaymentGateway {
  final String id;
  final String title;
  final String? description;
  final bool enabled;

  PaymentGateway({
    required this.id,
    required this.title,
    this.description,
    required this.enabled,
  });

  factory PaymentGateway.fromJson(Map<String, dynamic> json) {
    return PaymentGateway(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
class StripeSessionResponse {
  final String id;
  final String url;

  StripeSessionResponse({required this.id, required this.url});

  factory StripeSessionResponse.fromJson(Map<String, dynamic> json) {
    return StripeSessionResponse(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class PayPalOrderResponse {
  final String approvalUrl;

  PayPalOrderResponse({required this.approvalUrl});

  factory PayPalOrderResponse.fromJson(Map<String, dynamic> json) {
    return PayPalOrderResponse(
      approvalUrl: (json['approvalUrl'] ?? json['approval_url'] ?? '').toString(),
    );
  }
}

class PayPalOrderRequest {
  final int bookingId;

  PayPalOrderRequest(this.bookingId);

  Map<String, dynamic> toJson() => {'booking_id': bookingId};
}

class PayPalExecuteRequest {
  final String orderId;
  final int bookingId;

  PayPalExecuteRequest(this.orderId, this.bookingId);

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'booking_id': bookingId,
  };
}

class PayPalExecuteResponse {
  final bool success;
  final String message;

  PayPalExecuteResponse({required this.success, required this.message});

  factory PayPalExecuteResponse.fromJson(Map<String, dynamic> json) {
    return PayPalExecuteResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
    );
  }
}

class StripeVerifyResponse {
  final bool success;
  final String? message;
  final int? bookingId;

  StripeVerifyResponse({required this.success, this.message, this.bookingId});

  factory StripeVerifyResponse.fromJson(Map<String, dynamic> json) {
    return StripeVerifyResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      bookingId: json['booking_id'] as int?,
    );
  }
}
