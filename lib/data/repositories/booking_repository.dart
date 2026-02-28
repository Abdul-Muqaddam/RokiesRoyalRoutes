import '../models/booking_models.dart';
import '../remote/api_service.dart';
import '../../core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'booking_repository.g.dart';

abstract class BookingRepository {
  Future<List<Trip>> getUpcomingTrips();
}

class BookingRepositoryImpl implements BookingRepository {
  final ApiService _apiService;

  BookingRepositoryImpl(this._apiService);

  @override
  Future<List<Trip>> getUpcomingTrips() async {
    final response = await _apiService.getUserBookings();
    
    final trips = response.map((dto) {
      final status = _mapStatus(dto.status ?? 'pending');
      
      return Trip(
        id: dto.id.toString(),
        title: _cleanTitle(dto.title ?? ''),
        dateTime: _formatDateTime(dto),
        status: status,
        vehicleType: 'Executive Sedan', // Default from Kotlin repo
        pickupDate: dto.pickupDate,
        pickupTime: dto.pickupTime,
      );
    }).toList();

    // Filtering logic similar to Kotlin getUpcomingTrips
    final now = DateTime.now();
    return trips.where((trip) {
      if (trip.pickupDate == null || trip.pickupTime == null) return false;
      try {
        // Simple date comparison for now, Kotlin repo has complex timezone logic
        final tripDate = DateTime.parse('${trip.pickupDate} ${trip.pickupTime}');
        return tripDate.isAfter(now) || tripDate.isAtSameMomentAs(now);
      } catch (e) {
        return false;
      }
    }).toList()
      ..sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
  }

  TripStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'publish':
      case 'confirmed':
        return TripStatus.confirmed;
      case 'cancelled':
        return TripStatus.cancelled;
      case 'past':
        return TripStatus.past;
      default:
        return TripStatus.pending;
    }
  }

  String _cleanTitle(String title) {
    // Ported regex from Kotlin: Regex(" - \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$")
    final regex = RegExp(r' - \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');
    return title.replaceFirst(regex, '');
  }

  String _formatDateTime(UserBookingResponse dto) {
    if (dto.pickupDate == null || dto.pickupTime == null) return 'Unknown';
    return '${dto.pickupDate} at ${dto.pickupTime}';
  }
}

@riverpod
BookingRepository bookingRepository(Ref ref) {
  final apiService = ApiService(ref.watch(dioProvider));
  return BookingRepositoryImpl(apiService);
}
