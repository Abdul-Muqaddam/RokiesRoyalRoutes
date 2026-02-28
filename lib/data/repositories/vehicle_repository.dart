import '../models/vehicle_models.dart';
import '../remote/api_service.dart';
import '../../core/network/dio_client.dart';
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
      imageUrl: dto.image,
      passengers: int.tryParse(dto.passengerCapacity) ?? 0,
    )).toList();
  }
}

@riverpod
VehicleRepository vehicleRepository(Ref ref) {
  final apiService = ApiService(ref.watch(dioProvider));
  return VehicleRepositoryImpl(apiService);
}
