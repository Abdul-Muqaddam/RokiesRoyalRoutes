import '../models/vehicle_models.dart';
import '../remote/api_service.dart';
import '../../core/network/dio_client.dart';
import '../local/preferences_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vehicle_repository.g.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles();
}

class VehicleRepositoryImpl implements VehicleRepository {
  final ApiService _apiService;

  VehicleRepositoryImpl(this._apiService);

  @override
  Future<List<Vehicle>> getVehicles() async {
    final dtos = await _apiService.getVehicles();
    return dtos.map((dto) => Vehicle(
      id: dto.id.toString(),
      name: dto.title,
      model: dto.description,
      imageUrl: dto.image,
      passengers: int.tryParse(dto.passengerCapacity) ?? 0,
      luggage: int.tryParse(dto.luggageCapacity) ?? 0,
      price: double.tryParse(dto.basePrice) ?? 0.0,
      currency: dto.currency ?? 'CAD',
      type: dto.vehicleType,
      category: dto.vehicleType,
    )).toList();
  }
}

@riverpod
VehicleRepository vehicleRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VehicleRepositoryImpl(apiService);
}
