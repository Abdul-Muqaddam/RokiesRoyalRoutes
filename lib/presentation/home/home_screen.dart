import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../data/services/location_service.dart';
import '../../domain/repositories/booking_repository.dart';
import '../widgets/location_permission_sheet.dart';
import '../favourite/favourite_screen.dart';
import '../offer/offer_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/address_selection_sheet.dart';
import '../booking/booking_view_model.dart';
import '../wallet/wallet_screen.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../admin/admin_panel_screen.dart';
import '../../data/repositories/notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'widgets/active_ride_sheet.dart';
import '../../data/models/booking_models.dart';
import '../admin/live_tracking_screen.dart';

final activeTripsStreamProvider = StreamProvider<List<Trip>>((ref) {
  return ref.watch(bookingRepositoryProvider).watchBookings();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  GoogleMapController? _mapController;
  int _selectedIndex = 0;
  String _selectedService = 'Transport';
  LatLng? _currentPosition;
  LatLng? _pickupPosition;
  LatLng? _destinationPosition;
  String? _destinationName;
  String? _pickupName;
  String? _distance;
  String? _estimatedTime;
  Set<Polyline> _polylines = {};
  String? _activeTripIdPolylinesLoaded;
  LatLng? _lastDriverPositionForRoute;
  
  static const Color brandYellow = Color(0xFFDC423D);
  static const Color lightYellow = Color(0xFFFFEBEA);

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  // Listen for push notifications to instantly refresh the bookings list
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (mounted) {
      ref.invalidate(activeTripsStreamProvider);
    }
  });
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeLocation();
  });
}

@override
void dispose() {
  _tabController.dispose();
  super.dispose();
}


  Future<void> _initializeLocation() async {
    if (!mounted) return;
    
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final userConsented = await showLocationPermissionSheet(context);
      if (!userConsented || !mounted) return;
      permission = await ref.read(locationServiceProvider).requestLocationPermission() 
          ? LocationPermission.whileInUse 
          : LocationPermission.denied;
    }

    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 15),
          );
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    }
  }

  Future<void> _updateMapForTrip() async {
    if (_destinationName == null || _destinationName!.isEmpty) return;

    try {
      LatLng pickupLatLng;
      if (_pickupName == null || _pickupName == 'Current location' || _pickupName!.isEmpty) {
        if (_currentPosition == null) return;
        pickupLatLng = _currentPosition!;
      } else {
        List<geo.Location> pickupLocs = await geo.locationFromAddress(_pickupName!);
        if (pickupLocs.isEmpty) return;
        pickupLatLng = LatLng(pickupLocs.first.latitude, pickupLocs.first.longitude);
      }

      List<geo.Location> destLocs = await geo.locationFromAddress(_destinationName!);
      if (destLocs.isEmpty) return;
      final destLatLng = LatLng(destLocs.first.latitude, destLocs.first.longitude);

      final points = await ref.read(bookingRepositoryProvider).getDirections(
        pickupLatLng,
        destLatLng,
      );

      final distanceResponse = await ref.read(bookingRepositoryProvider).getDistanceMatrix(
        "${pickupLatLng.latitude},${pickupLatLng.longitude}",
        "${destLatLng.latitude},${destLatLng.longitude}",
      );

      String? dist;
      String? time;
      if (distanceResponse.rows.isNotEmpty && distanceResponse.rows.first.elements.isNotEmpty) {
        final element = distanceResponse.rows.first.elements.first;
        dist = element.distance?.text;
        time = element.duration?.text;
      }

      if (mounted) {
        setState(() {
          _pickupPosition = pickupLatLng;
          _destinationPosition = destLatLng;
          _distance = dist;
          _estimatedTime = time;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: brandYellow,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });
        _fitMapBounds();
      }
    } catch (e) {
      debugPrint('Error updating map for trip: $e');
    }
  }

  Future<void> _handleLocationSelected(Map<String, String> place) async {
    final address = place['address'] ?? '';
    final name = place['title'] ?? address;
    if (address.isEmpty) return;

    setState(() {
      _destinationName = name;
      _pickupName = 'Current location';
    });
    
    await _updateMapForTrip();
  }

  void _clearDestination() {
    setState(() {
      _destinationName = null;
      _destinationPosition = null;
      _pickupPosition = null;
      _distance = null;
      _estimatedTime = null;
      _polylines = {};
    });
    if (_currentPosition != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 15));
    }
  }

  void _fitMapBounds() {
    final pickup = _pickupPosition ?? _currentPosition;
    if (_mapController == null || pickup == null || _destinationPosition == null) return;

    LatLngBounds bounds;
    if (pickup.latitude > _destinationPosition!.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(_destinationPosition!.latitude, _destinationPosition!.longitude < pickup.longitude ? _destinationPosition!.longitude : pickup.longitude),
        northeast: LatLng(pickup.latitude, _destinationPosition!.longitude > pickup.longitude ? _destinationPosition!.longitude : pickup.longitude),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(pickup.latitude, pickup.longitude < _destinationPosition!.longitude ? pickup.longitude : _destinationPosition!.longitude),
        northeast: LatLng(_destinationPosition!.latitude, pickup.longitude > _destinationPosition!.longitude ? pickup.longitude : _destinationPosition!.longitude),
      );
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120.h));
  }

  void _fitMapForActiveTrip(Trip activeTrip, LatLng? driverPosition) {
    if (_mapController == null) return;
    
    final pickupCoords = parseLatLngFromString(activeTrip.pickupLocation);
    if (pickupCoords == null || pickupCoords.length < 2) return;
    final pickupLatLng = LatLng(pickupCoords[0], pickupCoords[1]);

    if (driverPosition != null) {
      LatLngBounds bounds;
      if (pickupLatLng.latitude > driverPosition.latitude) {
        bounds = LatLngBounds(
          southwest: LatLng(
            driverPosition.latitude, 
            driverPosition.longitude < pickupLatLng.longitude ? driverPosition.longitude : pickupLatLng.longitude
          ),
          northeast: LatLng(
            pickupLatLng.latitude, 
            driverPosition.longitude > pickupLatLng.longitude ? driverPosition.longitude : pickupLatLng.longitude
          ),
        );
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(
            pickupLatLng.latitude, 
            pickupLatLng.longitude < driverPosition.longitude ? pickupLatLng.longitude : driverPosition.longitude
          ),
          northeast: LatLng(
            driverPosition.latitude, 
            pickupLatLng.longitude > driverPosition.longitude ? pickupLatLng.longitude : driverPosition.longitude
          ),
        );
      }
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120.h));
    } else {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pickupLatLng, 15));
    }
  }

  Future<void> _loadActiveTripRoute(Trip activeTrip, LatLng? driverLatLng) async {
    try {
      final pickupCoords = parseLatLngFromString(activeTrip.pickupLocation);
      if (pickupCoords == null || pickupCoords.length < 2) return;
      final pickupLatLng = LatLng(pickupCoords[0], pickupCoords[1]);

      // confirmed + inProgress = driver is still heading to the passenger pickup location
      final isDriverEnRoute = activeTrip.status == TripStatus.confirmed ||
          activeTrip.status == TripStatus.inProgress;
      // arrived = driver has reached pickup, passenger is now in the car heading to dropoff
      final isTripActive = activeTrip.status == TripStatus.arrived;

      final newPolylines = <Polyline>{};

      // Route 1: driver → pickup (confirmed status with known driver position)
      if (isDriverEnRoute && driverLatLng != null) {
        try {
          final driverToPickupPoints = await ref.read(bookingRepositoryProvider).getDirections(
            driverLatLng,
            pickupLatLng,
          );
          if (driverToPickupPoints.isNotEmpty) {
            newPolylines.add(Polyline(
              polylineId: const PolylineId('driver_to_pickup'),
              points: driverToPickupPoints,
              color: brandYellow,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
          } else {
            // Fallback: straight line driver → pickup
            newPolylines.add(Polyline(
              polylineId: const PolylineId('driver_to_pickup_fallback'),
              points: [driverLatLng, pickupLatLng],
              color: brandYellow,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              jointType: JointType.round,
            ));
          }
        } catch (_) {
          // Fallback: straight dashed line
          newPolylines.add(Polyline(
            polylineId: const PolylineId('driver_to_pickup_fallback'),
            points: [driverLatLng, pickupLatLng],
            color: brandYellow,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            jointType: JointType.round,
          ));
        }
      }

      // Route 2: pickup → dropoff (inProgress or arrived)
      if (isTripActive) {
        final destCoords = parseLatLngFromString(activeTrip.dropoffLocation);
        if (destCoords != null && destCoords.length == 2) {
          final destLatLng = LatLng(destCoords[0], destCoords[1]);
          try {
            final tripPoints = await ref.read(bookingRepositoryProvider).getDirections(
              pickupLatLng,
              destLatLng,
            );
            if (tripPoints.isNotEmpty) {
              newPolylines.add(Polyline(
                polylineId: const PolylineId('pickup_to_dropoff'),
                points: tripPoints,
                color: brandYellow,
                width: 5,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ));
            } else {
              // Fallback: straight line pickup → dropoff
              newPolylines.add(Polyline(
                polylineId: const PolylineId('pickup_to_dropoff_fallback'),
                points: [pickupLatLng, destLatLng],
                color: brandYellow,
                width: 4,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                jointType: JointType.round,
              ));
            }
          } catch (_) {
            newPolylines.add(Polyline(
              polylineId: const PolylineId('pickup_to_dropoff_fallback'),
              points: [pickupLatLng, destLatLng],
              color: brandYellow,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              jointType: JointType.round,
            ));
          }
        }
      }

      if (mounted && newPolylines.isNotEmpty) {
        setState(() {
          _polylines = newPolylines;
        });
      }
    } catch (e) {
      debugPrint('Error loading active trip route: $e');
    }
  }

  void _showAddressSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionSheet(
        onLocationSelected: (data) async {
          final to = data['to'] ?? '';
          final from = data['from'] ?? '';
          
          setState(() {
            _destinationName = to;
            _pickupName = from;
          });

          // Sync with booking view model
          ref.read(bookingViewModelProvider.notifier).updatePickupLocation(from);
          ref.read(bookingViewModelProvider.notifier).updateDestination(to);
          
          await _updateMapForTrip();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final isAdmin = userProfileAsync.maybeWhen(
      data: (user) => user.role == 'admin' || user.email.toLowerCase().contains('admin'),
      orElse: () => false,
    );

    // Watch the active trips stream at build() level — required by Riverpod
    final tripsStream = ref.watch(activeTripsStreamProvider);
    final activeTrip = tripsStream.maybeWhen(
      data: (trips) {
        try {
          return trips.firstWhere((trip) =>
              trip.status == TripStatus.inProgress ||
              trip.status == TripStatus.arrived ||
              trip.status == TripStatus.confirmed);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    // Watch driver location if trip is active and has a driver
    final driverLatLng = (activeTrip != null && activeTrip.driverId != null)
        ? ref.watch(trackingStateProvider(activeTrip.driverId!)).position
        : null;

    if (activeTrip != null) {
      // Include whether driver pos is available in key so we re-fetch when it first appears
      final hasDriverPos = driverLatLng != null;
      final cacheKey = '${activeTrip.id}_${activeTrip.status.name}_$hasDriverPos';

      final driverMovedSignificantly = driverLatLng != null &&
          _lastDriverPositionForRoute != null &&
          ((_lastDriverPositionForRoute!.latitude - driverLatLng.latitude).abs() > 0.002 ||
              (_lastDriverPositionForRoute!.longitude - driverLatLng.longitude).abs() > 0.002);

      if (_activeTripIdPolylinesLoaded != cacheKey || driverMovedSignificantly) {
        _activeTripIdPolylinesLoaded = cacheKey;
        _lastDriverPositionForRoute = driverLatLng;
        Future.microtask(() => _loadActiveTripRoute(activeTrip, driverLatLng));
      }
      if (_mapController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapForActiveTrip(activeTrip, driverLatLng);
        });
      }
    } else {
      if (_activeTripIdPolylinesLoaded != null) {
        // The trip just finished or was cancelled, clear the map back to default home state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _clearDestination();
          }
        });
      }
      _activeTripIdPolylinesLoaded = null;
      _lastDriverPositionForRoute = null;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          _buildMainContent(activeTrip, driverLatLng),
          if (_selectedIndex != 0 || activeTrip == null) _buildCustomBottomNav(isAdmin),
        ],
      ),
    );
  }

  Widget _buildMainContent(Trip? activeTrip, LatLng? driverPosition) {
    switch (_selectedIndex) {
      case 0:
        return Stack(
          children: [
            _buildMap(activeTrip, driverPosition),
            _buildTopActions(),
            _buildMapControls(),
            if (activeTrip != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ActiveRideSheet(trip: activeTrip),
              )
            else
              _buildBottomSearchCard(),
          ],
        );
      case 1:
        return const FavouriteScreen();
      case 2:
        return const WalletScreen();
      case 3:
        return const OfferScreen();
      case 4:
        return const ProfileScreen();
      case 5:
        return const AdminPanelScreen(isTab: true);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMap(Trip? activeTrip, LatLng? driverPosition) {
    LatLng? pickupLatLng;
    LatLng? destinationLatLng;

    if (activeTrip != null) {
      final pickupCoords = parseLatLngFromString(activeTrip.pickupLocation);
      if (pickupCoords != null && pickupCoords.length == 2) {
        pickupLatLng = LatLng(pickupCoords[0], pickupCoords[1]);
      }
      final destCoords = parseLatLngFromString(activeTrip.dropoffLocation);
      if (destCoords != null && destCoords.length == 2) {
        destinationLatLng = LatLng(destCoords[0], destCoords[1]);
      }
    } else {
      pickupLatLng = _pickupPosition;
      destinationLatLng = _destinationPosition;
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition ?? const LatLng(30.1575, 71.5249),
        zoom: 14.0,
      ),
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      style: _mapStyle,
      markers: {
        if (_currentPosition != null && pickupLatLng == null)
          Marker(
            markerId: const MarkerId('user_pos'),
            position: _currentPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        if (pickupLatLng != null)
          Marker(
            markerId: const MarkerId('pickup_pos'),
            position: pickupLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ),
        if (destinationLatLng != null)
          Marker(
            markerId: const MarkerId('dest_pos'),
            position: destinationLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: activeTrip != null ? 'Dropoff Location' : (_destinationName ?? 'Destination')),
          ),
        if (driverPosition != null)
          Marker(
            markerId: const MarkerId('driver_pos'),
            position: driverPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Driver Location'),
          ),
      },
      circles: (_currentPosition == null || activeTrip != null) ? {} : {
        Circle(
          circleId: const CircleId('user_glow'),
          center: _currentPosition!,
          radius: 100, 
          fillColor: brandYellow.withOpacity(0.15),
          strokeWidth: 0,
        ),
      },
      polylines: _polylines,
    );
  }

  Widget _buildTopActions() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 15.h, left: 20.w, right: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleWhiteButton(Icons.menu, onTap: () => _scaffoldKey.currentState?.openDrawer()),
              Row(
                children: [
                  _buildCircleWhiteButton(Icons.search, onTap: () async {
                    final result = await context.push<Map<String, String>>('/search');
                    if (result != null) {
                      _handleLocationSelected(result);
                    }
                  }),
                  SizedBox(width: 10.w),
                  _buildBellButton(context, ref),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    final hasDestination = _destinationName != null;
    final bottomPosition = hasDestination ? 335.h : 265.h;

    return Positioned(
      bottom: bottomPosition,
      right: 20.w,
      child: _buildCircleWhiteButton(Icons.my_location, onTap: () {
        if (_currentPosition != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 16),
          );
        }
      }),
    );
  }

  Widget _buildCircleWhiteButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEA),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20.sp),
      ),
    );
  }

  Widget _buildBellButton(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    return GestureDetector(
      onTap: () => context.push('/notification'),
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEA),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Center(child: Icon(Icons.notifications_none, color: Colors.black87, size: 20.sp)),
            if (unreadCount > 0)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: const BoxDecoration(color: brandYellow, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSearchCard() {
    return Positioned(
      bottom: 115.h,
      left: 12.w,
      right: 12.w,
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: lightYellow.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: brandYellow.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _showAddressSelectionSheet,
              child: Container(
                height: 52.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: brandYellow.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.black38, size: 20.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _destinationName ?? 'Where would you go?',
                        style: TextStyle(
                          color: _destinationName != null ? Colors.black87 : Colors.grey[400],
                          fontSize: 14.sp,
                          fontWeight: _destinationName != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_destinationName != null)
                      GestureDetector(
                        onTap: _clearDestination,
                        child: Icon(Icons.close, color: Colors.grey[600], size: 20.sp),
                      )
                    else
                      Icon(Icons.favorite_border, color: Colors.grey[400], size: 20.sp),
                  ],
                ),
              ),
            ),
            if (_distance != null || _estimatedTime != null) ...[
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: brandYellow, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      '${_distance ?? ""} (${_estimatedTime ?? ""})',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 10.h),
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: brandYellow.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildToggleButton('Transport', _selectedService == 'Transport')),
                  Expanded(child: _buildToggleButton('Delivery', _selectedService == 'Delivery')),
                  Expanded(child: _buildToggleButton('Rental', _selectedService == 'Rental')),
                ],
              ),
            ),
            if (_destinationName != null) ...[
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () async {
                    // Sync with booking view model
                    String pickup = _pickupName ?? 'Current location';
                    if (pickup == 'Current location' || pickup.isEmpty) {
                      // Attempt to reverse geocode the current position to get a real address
                      final resolved = await ref.read(locationServiceProvider).getCurrentLocationName();
                      if (resolved != null && resolved.isNotEmpty && resolved != 'Permission denied') {
                        pickup = resolved;
                      }
                      if (_currentPosition != null) {
                        pickup = '$pickup (${_currentPosition!.latitude}, ${_currentPosition!.longitude})';
                      }
                    } else {
                      try {
                        final locs = await geo.locationFromAddress(pickup);
                        if (locs.isNotEmpty) {
                          pickup = '$pickup (${locs.first.latitude}, ${locs.first.longitude})';
                        }
                      } catch (_) {}
                    }
                    String dest = _destinationName ?? '';
                    if (dest.isNotEmpty) {
                      try {
                        final locs = await geo.locationFromAddress(dest);
                        if (locs.isNotEmpty) {
                          dest = '$dest (${locs.first.latitude}, ${locs.first.longitude})';
                        }
                      } catch (_) {}
                    }
                    
                    final bookingNotifier = ref.read(bookingViewModelProvider.notifier);
                    bookingNotifier.updatePickupLocation(pickup);
                    bookingNotifier.updateDestination(dest);
                    
                    // Trigger distance calculation since it was reset
                    await bookingNotifier.calculateDistance();
                    
                    // Navigate to vehicle selection or booking
                    if (context.mounted) {
                      context.push('/available-cars');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandYellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: Text(
                    'Continue Booking',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedService = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: isSelected ? brandYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNav(bool isAdmin) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 100.h,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(size: Size(1.sw, 80.h), painter: NotchedBottomBarPainter()),
            Container(
              height: 80.h,
              padding: EdgeInsets.only(left: 10.w, right: 10.w, bottom: 8.h),
              child: Row(
                children: [
                  Expanded(child: _buildNavItem(0, 'Home', Icons.home)),
                  Expanded(child: _buildNavItem(1, 'Favourite', Icons.favorite_border)),
                  SizedBox(width: 80.w),
                  Expanded(
                    child: isAdmin 
                        ? _buildNavItem(5, 'Admin', Icons.admin_panel_settings_outlined)
                        : _buildNavItem(3, 'Offer', Icons.percent),
                  ),
                  Expanded(child: _buildNavItem(4, 'Profile', Icons.person_outline)),
                ],
              ),
            ),
            Positioned(bottom: 25.h, child: _buildHexagonWalletButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? brandYellow : Colors.grey[400], size: 22.sp),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: isSelected ? brandYellow : Colors.grey[400], fontSize: 10.sp, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHexagonWalletButton() {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            painter: HexagonPainter(color: brandYellow),
            child: Container(
              width: 68.w,
              height: 74.h,
              alignment: Alignment.center,
              child: Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28.sp),
            ),
          ),
          SizedBox(height: 2.h),
          Text('Wallet', style: TextStyle(color: _selectedIndex == 2 ? brandYellow : Colors.grey[400], fontSize: 10.sp, fontWeight: _selectedIndex == 2 ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  final String _mapStyle = '''[{"featureType": "poi", "stylers": [{"visibility": "off"}]},{"featureType": "transit", "stylers": [{"visibility": "off"}]},{"featureType": "water", "stylers": [{"color": "#e9e9e9"}]},{"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#ffffff"}]},{"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#f1f1f1"}]}]''';
}

class HexagonPainter extends CustomPainter {
  final Color color;
  HexagonPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width, h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NotchedBottomBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width, h = size.height;
    final r = 30.0, cutoutWidth = 90.0, cutoutHeight = 35.0;
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(w * 0.5 - cutoutWidth * 0.5, 0);
    path.quadraticBezierTo(w * 0.5 - cutoutWidth * 0.3, 0, w * 0.5 - cutoutWidth * 0.2, cutoutHeight * 0.5);
    path.quadraticBezierTo(w * 0.5, cutoutHeight, w * 0.5 + cutoutWidth * 0.2, cutoutHeight * 0.5);
    path.quadraticBezierTo(w * 0.5 + cutoutWidth * 0.3, 0, w * 0.5 + cutoutWidth * 0.5, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawShadow(path, Colors.black, 10, false);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
