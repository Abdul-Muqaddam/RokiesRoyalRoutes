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
    final bookingsAsync = ref.watch(bookingsStreamProvider);
    final tabIndex = state.valueOrNull?.selectedTab ?? 0;

    return bookingsAsync.when(
      data: (allTrips) => _processTrips(allTrips, tabIndex),
      loading: () => TripsState(selectedTab: tabIndex, trips: [], isLoading: true),
      error: (err, stack) => TripsState(selectedTab: tabIndex, trips: [], isLoading: false),
    );
  }

  TripsState _processTrips(List<Trip> allTrips, int tabIndex) {
    List<Trip> filteredTrips;
    final now = DateTime.now();

    switch (tabIndex) {
      case 1: // Upcoming
        filteredTrips = allTrips.where((trip) {
          if (trip.pickupDate == null || trip.pickupTime == null) return false;
          try {
            if (trip.pickupTime!.toLowerCase() == 'now') {
              final tripDate = DateTime.parse('${trip.pickupDate}');
              final today = DateTime(now.year, now.month, now.day);
              return tripDate.isAfter(today) || tripDate.isAtSameMomentAs(today);
            }
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
            if (trip.pickupTime!.toLowerCase() == 'now') {
              final tripDate = DateTime.parse('${trip.pickupDate}');
              final today = DateTime(now.year, now.month, now.day);
              return tripDate.isBefore(today);
            }
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

  void selectTab(int index) {
    state = AsyncValue.data(
      _processTrips(ref.read(bookingsStreamProvider).value ?? [], index),
    );
  }

  Future<void> refresh() async {
    // ref.invalidate(bookingsStreamProvider) will trigger a refresh of the stream
    ref.invalidate(bookingsStreamProvider);
  }
}
