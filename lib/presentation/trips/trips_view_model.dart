import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/booking_models.dart';
import '../../domain/repositories/booking_repository.dart';

part 'trips_view_model.g.dart';

class TripsState {
  final int selectedTab;
  final List<Trip> trips;
  final bool isLoading;

  TripsState({
    required this.selectedTab,
    required this.trips,
    required this.isLoading,
  });

  TripsState copyWith({
    int? selectedTab,
    List<Trip>? trips,
    bool? isLoading,
  }) {
    return TripsState(
      selectedTab: selectedTab ?? this.selectedTab,
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class TripsViewModel extends _$TripsViewModel {
  @override
  FutureOr<TripsState> build() async {
    return _fetchTrips(0);
  }

  Future<TripsState> _fetchTrips(int tabIndex) async {
    final repository = ref.read(bookingRepositoryProvider);
    final allTrips = await repository.getAllTrips();
    
    List<Trip> filteredTrips;
    final now = DateTime.now();

    switch (tabIndex) {
      case 1: // Upcoming
        filteredTrips = allTrips.where((trip) {
          if (trip.pickupDate == null || trip.pickupTime == null) return false;
          try {
            final tripDate = DateTime.parse('${trip.pickupDate} ${trip.pickupTime}');
            return tripDate.isAfter(now) || tripDate.isAtSameMomentAs(now);
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 2: // Past
        filteredTrips = allTrips.where((trip) {
          if (trip.pickupDate == null || trip.pickupTime == null) return true;
          try {
            final tripDate = DateTime.parse('${trip.pickupDate} ${trip.pickupTime}');
            return tripDate.isBefore(now);
          } catch (e) {
            return true;
          }
        }).toList();
        break;
      case 0: // All
      default:
        filteredTrips = allTrips;
        break;
    }

    return TripsState(
      selectedTab: tabIndex,
      trips: filteredTrips,
      isLoading: false,
    );
  }

  Future<void> selectTab(int index) async {
    // Keep previous data while loading to avoid full screen flicker/disappearance
    if (state.hasValue) {
      state = const AsyncValue<TripsState>.loading().copyWithPrevious(state);
    } else {
      state = const AsyncValue<TripsState>.loading();
    }
    state = await AsyncValue.guard(() => _fetchTrips(index));
  }

  Future<void> refresh() async {
    if (state.hasValue) {
      state = const AsyncValue<TripsState>.loading().copyWithPrevious(state);
    } else {
      state = const AsyncValue<TripsState>.loading();
    }
    state = await AsyncValue.guard(() => _fetchTrips(state.value?.selectedTab ?? 0));
  }
}
