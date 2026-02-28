import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/user_models.dart';
import '../../data/models/vehicle_models.dart';
import '../../data/models/booking_models.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/repositories/booking_repository.dart';

part 'home_view_model.g.dart';

class HomeState {
  final UserDto user;
  final List<Vehicle> vehicles;
  final Trip? latestUpcomingTrip;

  HomeState({
    required this.user,
    required this.vehicles,
    this.latestUpcomingTrip,
  });
}

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  Future<HomeState> build() async {
    final userProfile = await ref.watch(userProfileProvider.future);
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);
    final bookingRepo = ref.watch(bookingRepositoryProvider);

    final vehicles = await vehicleRepo.getVehicles();
    final upcomingTrips = await bookingRepo.getUpcomingTrips();

    return HomeState(
      user: userProfile,
      vehicles: vehicles,
      latestUpcomingTrip: upcomingTrips.isNotEmpty ? upcomingTrips.first : null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userProfile = await ref.refresh(userProfileProvider.future);
      final vehicleRepo = ref.refresh(vehicleRepositoryProvider);
      final bookingRepo = ref.refresh(bookingRepositoryProvider);

      final vehicles = await vehicleRepo.getVehicles();
      final upcomingTrips = await bookingRepo.getUpcomingTrips();

      return HomeState(
        user: userProfile,
        vehicles: vehicles,
        latestUpcomingTrip: upcomingTrips.isNotEmpty ? upcomingTrips.first : null,
      );
    });
  }
}
