import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTrackingService {
  final _supabase = Supabase.instance.client;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Future<void> startTracking() async {
    if (_isTracking) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Tracking failed: Location permission not granted.');
      return;
    }

    _isTracking = true;
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Update every 2 meters for high-precision live feel
      ),
    ).listen((Position position) {
      debugPrint('📡 [TRACKING] New position: ${position.latitude}, ${position.longitude}');
      _updateLocationInSupabase(position);
    }, onError: (e) {
      debugPrint('❌ [TRACKING] Stream Error: $e');
      stopTracking();
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _updateOnlineStatus(false);
  }

  Future<void> _updateLocationInSupabase(Position position) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ [TRACKING] No authenticated user found.');
      return;
    }

    try {
      debugPrint('📤 [TRACKING] Pushing to Supabase for driver: ${user.id}');
      await _supabase.from('driver_status').upsert({
        'driver_id': user.id,
        'lat': position.latitude,
        'lng': position.longitude,
        'last_updated_at': DateTime.now().toIso8601String(),
        'is_online': true,
      });
      debugPrint('✅ [TRACKING] Upsert successful.');
    } catch (e) {
      debugPrint('❌ [TRACKING] Supabase Update Error: $e');
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('driver_status').upsert({
        'driver_id': user.id,
        'is_online': isOnline,
        'last_updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}

final driverTrackingServiceProvider = Provider<DriverTrackingService>((ref) {
  return DriverTrackingService();
});
