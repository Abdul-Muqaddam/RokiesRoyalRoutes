
class VehicleDto {
  final int id;
  final String title;
  final String description;
  final String image;
  final String vehicleType;
  final String passengerCapacity;
  final String luggageCapacity;
  final String basePrice;
  final String pricePerKm;
  final String pricePerHour;
  final String? currency;

  VehicleDto({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.vehicleType,
    required this.passengerCapacity,
    required this.luggageCapacity,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerHour,
    this.currency,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? json['type'] ?? '').toString(),
      passengerCapacity: (json['passenger_capacity'] ?? '').toString(),
      luggageCapacity: (json['luggage_capacity'] ?? '').toString(),
      basePrice: (json['base_price'] ?? '').toString(),
      pricePerKm: (json['price_per_km'] ?? '').toString(),
      pricePerHour: (json['price_per_hour'] ?? '').toString(),
      currency: json['currency']?.toString(),
    );
  }
}

class Vehicle {
  final String id;
  final String name;
  final String imageUrl;
  final int passengers;

  Vehicle({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.passengers,
  });
}
