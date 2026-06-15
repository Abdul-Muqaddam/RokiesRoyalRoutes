class Vehicle {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String vehicleType;
  final int passengerCapacity;
  final int luggageCapacity;
  final double basePrice;
  final double pricePerKm;
  final double pricePerHour;
  final String currency;
  final String? maxPower;
  final String? fuelEfficiency;
  final String? maxSpeed;
  final String? acceleration;
  final String? color;
  final String? fuelType;
  final String? gearType;

  Vehicle({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.vehicleType,
    required this.passengerCapacity,
    required this.luggageCapacity,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerHour,
    required this.currency,
    this.maxPower,
    this.fuelEfficiency,
    this.maxSpeed,
    this.acceleration,
    this.color,
    this.fuelType,
    this.gearType,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    String imageUrl = (map['image_url'] ?? '').toString();
    
    // If the URL is just a filename/path (no http), build the full Supabase Storage URL
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      const String projectRef = 'arbwxotsjasszmcftxzg';
      imageUrl = 'https://$projectRef.supabase.co/storage/v1/object/public/vehicles/$imageUrl';
    }

    return Vehicle(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: imageUrl,
      vehicleType: map['vehicle_type'] ?? '',
      passengerCapacity: map['passenger_capacity'] ?? 0,
      luggageCapacity: map['luggage_capacity'] ?? 0,
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 0.0,
      pricePerKm: (map['price_per_km'] as num?)?.toDouble() ?? 0.0,
      pricePerHour: (map['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      maxPower: map['max_power']?.toString(),
      fuelEfficiency: map['fuel_efficiency']?.toString(),
      maxSpeed: map['max_speed']?.toString(),
      acceleration: map['acceleration_0_60']?.toString(),
      color: map['color']?.toString(),
      fuelType: map['fuel_type']?.toString(),
      gearType: map['gear_type']?.toString(),
    );
  }
}
