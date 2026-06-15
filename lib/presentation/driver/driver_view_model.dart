import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/booking_models.dart';

// ─── Driver State ───────────────────────────────────────────────────────────

class DriverDashboardState {
  final List<Trip> assignedTrips;
  final int todayTripsCount;
  final double totalEarnings;
  final double rating;
  final bool isLoading;
  final String? error;

  const DriverDashboardState({
    this.assignedTrips = const [],
    this.todayTripsCount = 0,
    this.totalEarnings = 0.0,
    this.rating = 0.0,
    this.isLoading = false,
    this.error,
  });

  DriverDashboardState copyWith({
    List<Trip>? assignedTrips,
    int? todayTripsCount,
    double? totalEarnings,
    double? rating,
    bool? isLoading,
    String? error,
  }) {
    return DriverDashboardState(
      assignedTrips: assignedTrips ?? this.assignedTrips,
      todayTripsCount: todayTripsCount ?? this.todayTripsCount,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── ViewModel ──────────────────────────────────────────────────────────────

class DriverViewModel extends AutoDisposeAsyncNotifier<DriverDashboardState> {
  final _supabase = Supabase.instance.client;

  @override
  Future<DriverDashboardState> build() async {
    // Start listening for changes immediately
    _listenToChanges();
    return _fetchDashboard();
  }

  void _listenToChanges() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
        .channel('driver-dashboard-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: user.id,
          ),
          callback: (payload) {
            print('DEBUG: Real-time update received for driver dashboard');
            refresh();
          },
        )
        .subscribe();
  }

  Future<DriverDashboardState> _fetchDashboard() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const DriverDashboardState(error: 'Not logged in');

    try {
      // Fetch all bookings assigned to this driver
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('driver_id', user.id)
          .order('created_at', ascending: false);

      final allTrips = (response as List)
          .map((data) => _mapJsonToTrip(data))
          .toList();

      // Today's trips
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayTrips =
          allTrips.where((t) => t.pickupDate == todayStr).toList();

      // Total earnings from completed bookings
      double earnings = 0;
      for (final data in response) {
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'completed' || status == 'past') {
          final rawPrice = data['total_price'];
          if (rawPrice != null) {
            earnings += double.tryParse(rawPrice.toString()) ?? 0;
          }
        }
      }

      // Rating from driver_ratings table
      double rating = 0.0;
      try {
        final ratingResponse = await _supabase
            .from('driver_ratings')
            .select('rating')
            .eq('driver_id', user.id);
        if ((ratingResponse as List).isNotEmpty) {
          final sum = ratingResponse.fold<double>(
              0, (prev, e) => prev + (double.tryParse(e['rating'].toString()) ?? 0));
          rating = sum / ratingResponse.length;
        }
      } catch (_) {
        final meta = user.userMetadata ?? {};
        rating = double.tryParse(meta['rating']?.toString() ?? '') ?? 0.0;
      }

      // Active assignments: pending + confirmed + inProgress
      final activeTrips = allTrips
          .where((t) =>
              t.status == TripStatus.pending ||
              t.status == TripStatus.confirmed ||
              t.status == TripStatus.inProgress)
          .toList();

      return DriverDashboardState(
        assignedTrips: activeTrips,
        todayTripsCount: todayTrips.length,
        totalEarnings: earnings,
        rating: rating,
      );
    } catch (e) {
      return DriverDashboardState(error: e.toString());
    }
  }

  Future<void> refresh() async {
    // We don't want to show a full loading state for real-time background updates
    // as it would flicker the UI. Just fetch and update.
    final newState = await _fetchDashboard();
    state = AsyncValue.data(newState);
  }

  Trip _mapJsonToTrip(Map<String, dynamic> data) {
    return Trip(
      id: data['id'].toString(),
      title: '${data['pickup_location']} → ${data['dropoff_location']}',
      dateTime: '${data['pickup_date']} at ${data['pickup_time']}',
      status: _mapStatus(data['status'] ?? 'pending'),
      vehicleType: data['vehicle_id']?.toString() ?? 'Vehicle',
      pickupDate: data['pickup_date'],
      pickupTime: data['pickup_time'],
      pickupLocation: data['pickup_location'],
      dropoffLocation: data['dropoff_location'],
      price: '${data['currency'] ?? 'CAD'} ${data['total_price'] ?? '0.00'}',
      reference: '#${data['id'].toString().substring(0, 8).toUpperCase()}',
      userId: data['user_id']?.toString(),
    );
  }

  TripStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return TripStatus.confirmed;
      case 'cancelled':
        return TripStatus.cancelled;
      case 'in_progress':
        return TripStatus.inProgress;
      case 'past':
      case 'completed':
        return TripStatus.past;
      default:
        return TripStatus.pending;
    }
  }
}

final driverViewModelProvider =
    AutoDisposeAsyncNotifierProvider<DriverViewModel, DriverDashboardState>(
  DriverViewModel.new,
);
