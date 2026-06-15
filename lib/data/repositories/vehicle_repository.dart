import '../models/vehicle_models.dart' as legacy;
import '../services/vehicle_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vehicle_repository.g.dart';

abstract class VehicleRepository {
  Future<List<legacy.Vehicle>> getVehicles();
}

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleService _vehicleService;

  VehicleRepositoryImpl(this._vehicleService);

  @override
  Future<List<legacy.Vehicle>> getVehicles() async {
    final supabaseVehicles = await _vehicleService.getVehicles();
    return supabaseVehicles.map((sv) => legacy.Vehicle(
      id: sv.id,
      name: sv.title,
      model: sv.description,
      imageUrl: sv.imageUrl,
      passengers: sv.passengerCapacity,
      luggage: sv.luggageCapacity,
      price: sv.basePrice,
      currency: sv.currency,
      type: sv.vehicleType,
      category: sv.vehicleType,
      maxPower: sv.maxPower,
      fuelEfficiency: sv.fuelEfficiency,
      maxSpeed: sv.maxSpeed,
      acceleration: sv.acceleration,
      color: sv.color,
      fuelType: sv.fuelType,
      gearType: sv.gearType,
    )).toList();
  }
}

@riverpod
VehicleRepository vehicleRepository(Ref ref) {
  return VehicleRepositoryImpl(VehicleService());
}

@riverpod
Future<List<legacy.Vehicle>> allVehicles(Ref ref) {
  return ref.watch(vehicleRepositoryProvider).getVehicles();
}
