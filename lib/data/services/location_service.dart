import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

class LocationService {
  Future<String?> getCurrentLocationName() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services disabled';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Permission denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Permission permanently denied';
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint('Error or timeout fetching current position: $e');
        // Fallback to last known position
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return 'Could not determine location';
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return _formatAddress(place);
      }
    } catch (e) {
      return 'Error detecting location';
    }
    return null;
  }

  String _formatAddress(Placemark place) {
    final number = place.subThoroughfare ?? place.name;
    final street = place.thoroughfare;
    final colony = place.subLocality;
    final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;

    final parts = [
      if (number != null && number.isNotEmpty) number,
      if (street != null && street.isNotEmpty && street != number) street,
      if (colony != null && colony.isNotEmpty) colony,
      if (city != null && city.isNotEmpty) city,
    ];

    return parts.join(', ');
  }
}

@riverpod
LocationService locationService(Ref ref) {
  return LocationService();
}

@riverpod
Future<String> currentLocation(Ref ref) async {
  final service = ref.watch(locationServiceProvider);
  final name = await service.getCurrentLocationName();
  return name ?? 'Unknown Location';
}
