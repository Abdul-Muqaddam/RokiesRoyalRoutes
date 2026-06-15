import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final _supabase = Supabase.instance.client;

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('is_active', true);

      return (response as List)
          .map((item) => Vehicle.fromMap(item))
          .toList();

    } catch (e) {
      throw Exception('Failed to fetch vehicles: $e');
    }
  }
}
