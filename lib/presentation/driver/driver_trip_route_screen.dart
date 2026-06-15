import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_models.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/services/push_notification_service.dart';
import '../../../data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_view_model.dart';

class DriverTripRouteScreen extends ConsumerStatefulWidget {
  final Trip trip;

  const DriverTripRouteScreen({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<DriverTripRouteScreen> createState() => _DriverTripRouteScreenState();
}

class _DriverTripRouteScreenState extends ConsumerState<DriverTripRouteScreen> {
  GoogleMapController? _mapController;
  LatLng? _driverLatLng;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;

  late TripStatus _tripStatus;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Route specs
  String? _distance;
  String? _duration;

  @override
  void initState() {
    super.initState();
    _tripStatus = widget.trip.status;
    _initializeTripData();
  }

  Future<void> _initializeTripData() async {
    try {
      // 1. Get driver current position
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        _driverLatLng = LatLng(pos.latitude, pos.longitude);
      }

      // 2. Parse/Geocode pickup
      final pickupCoords = parseLatLngFromString(widget.trip.pickupLocation);
      if (pickupCoords != null) {
        _pickupLatLng = LatLng(pickupCoords[0], pickupCoords[1]);
      } else if (widget.trip.pickupLocation != null &&
          cleanLocationName(widget.trip.pickupLocation) != 'Current location' &&
          widget.trip.pickupLocation!.isNotEmpty) {
        try {
          final cleanPickup = cleanLocationName(widget.trip.pickupLocation);
          final locs = await geo.locationFromAddress(cleanPickup);
          if (locs.isNotEmpty) {
            _pickupLatLng = LatLng(locs.first.latitude, locs.first.longitude);
          }
        } catch (e) {
          debugPrint('Error geocoding pickup: $e');
        }
      }
      
      // Fallback if pickup geocoding failed or was 'Current location'
      _pickupLatLng ??= _driverLatLng ?? const LatLng(37.4279613, -122.0857496);

      // 3. Parse/Geocode dropoff
      final dropoffCoords = parseLatLngFromString(widget.trip.dropoffLocation);
      if (dropoffCoords != null) {
        _dropoffLatLng = LatLng(dropoffCoords[0], dropoffCoords[1]);
      } else if (widget.trip.dropoffLocation != null && widget.trip.dropoffLocation!.isNotEmpty) {
        try {
          final cleanDropoff = cleanLocationName(widget.trip.dropoffLocation);
          final locs = await geo.locationFromAddress(cleanDropoff);
          if (locs.isNotEmpty) {
            _dropoffLatLng = LatLng(locs.first.latitude, locs.first.longitude);
          }
        } catch (e) {
          debugPrint('Error geocoding dropoff: $e');
        }
      }

      _dropoffLatLng ??= const LatLng(37.4219999, -122.0840575);

      // 4. Fetch Directions
      final repository = ref.read(bookingRepositoryProvider);
      _polylines = {};

      if (_tripStatus == TripStatus.confirmed || _tripStatus == TripStatus.pending) {
        // Fetch Segment 1: Driver -> Pickup
        final LatLng startLatLng1 = _driverLatLng ?? _pickupLatLng!;
        final LatLng endLatLng1 = _pickupLatLng!;
        final points1 = await repository.getDirections(startLatLng1, endLatLng1);

        // Fetch Segment 2: Pickup -> Dropoff
        final LatLng startLatLng2 = _pickupLatLng!;
        final LatLng endLatLng2 = _dropoffLatLng!;
        final points2 = await repository.getDirections(startLatLng2, endLatLng2);

        if (points1.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route_to_pickup'),
              points: points1,
              color: Colors.blue,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }
        if (points2.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route_to_dropoff'),
              points: points2,
              color: AppColors.gold,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }

        // Fetch Distance/Duration matrix from Driver to Pickup (for showing ETA to pickup)
        final distanceResponse = await repository.getDistanceMatrix(
          "${startLatLng1.latitude},${startLatLng1.longitude}",
          "${endLatLng1.latitude},${endLatLng1.longitude}",
        );

        if (distanceResponse.rows.isNotEmpty && distanceResponse.rows.first.elements.isNotEmpty) {
          final element = distanceResponse.rows.first.elements.first;
          _distance = element.distance?.text;
          _duration = element.duration?.text;
        } else {
          _distance = null;
          _duration = null;
        }
      } else {
        // Fetch Segment: Driver -> Dropoff
        final LatLng startLatLng = _driverLatLng ?? _pickupLatLng!;
        final LatLng endLatLng = _dropoffLatLng!;
        final points = await repository.getDirections(startLatLng, endLatLng);

        if (points.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: AppColors.gold,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }

        // Fetch Distance/Duration matrix from Driver to Dropoff (for showing ETA to dropoff)
        final distanceResponse = await repository.getDistanceMatrix(
          "${startLatLng.latitude},${startLatLng.longitude}",
          "${endLatLng.latitude},${endLatLng.longitude}",
        );

        if (distanceResponse.rows.isNotEmpty && distanceResponse.rows.first.elements.isNotEmpty) {
          final element = distanceResponse.rows.first.elements.first;
          _distance = element.distance?.text;
          _duration = element.duration?.text;
        } else {
          _distance = null;
          _duration = null;
        }
      }

      // 6. Build markers
      _updateMarkers();

      // 7. Subscribe to live position updates for the driver
      _subscribeToLiveLocation();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _fitMapBounds();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Could not load trip directions: $e');
      }
    }
  }

  void _subscribeToLiveLocation() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _driverLatLng = LatLng(position.latitude, position.longitude);
          _updateMarkers();
        });
      }
    }, onError: (err) {
      debugPrint('Error in live position stream: $err');
    });
  }

  void _updateMarkers() {
    final markersSet = <Marker>{};

    if (_driverLatLng != null) {
      markersSet.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You (Driver)'),
        ),
      );
    }

    if (_pickupLatLng != null) {
      markersSet.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Pickup', snippet: cleanLocationName(widget.trip.pickupLocation)),
        ),
      );
    }

    if (_dropoffLatLng != null) {
      markersSet.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Destination', snippet: cleanLocationName(widget.trip.dropoffLocation)),
        ),
      );
    }

    _markers = markersSet;
  }

  void _fitMapBounds() {
    if (_mapController == null || _pickupLatLng == null || _dropoffLatLng == null) return;

    final bounds = _getBounds(_pickupLatLng!, _dropoffLatLng!, _driverLatLng);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.w));
  }

  LatLngBounds _getBounds(LatLng p1, LatLng p2, LatLng? driver) {
    double minLat = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
    double maxLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    double minLng = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
    double maxLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;

    if (driver != null) {
      if (driver.latitude < minLat) minLat = driver.latitude;
      if (driver.latitude > maxLat) maxLat = driver.latitude;
      if (driver.longitude < minLng) minLng = driver.longitude;
      if (driver.longitude > maxLng) maxLng = driver.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _launchNavigation() async {
    final LatLng? target = (_tripStatus == TripStatus.confirmed || _tripStatus == TripStatus.pending)
        ? _pickupLatLng
        : _dropoffLatLng;
    if (target == null) return;
    
    final url = 'google.navigation:q=${target.latitude},${target.longitude}&mode=d';
    final fallbackUrl = 'https://www.google.com/maps/dir/?api=1&destination=${target.latitude},${target.longitude}&travelmode=driving';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch navigation: $e');
    }
  }

  Future<void> _updateStatus(String newStatusStr, TripStatus newStatusEnum) async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(bookingRepositoryProvider)
          .updateBookingStatus(widget.trip.id, newStatusStr);

      if (success) {
        // Trigger background viewmodel refresh
        ref.read(driverViewModelProvider.notifier).refresh();

        setState(() {
          _tripStatus = newStatusEnum;
        });

        // Re-load the trip route maps for the new state
        await _initializeTripData();

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (newStatusEnum == TripStatus.past) {
            _showCompletionDialog();
          }
        }
      } else {
        throw Exception('Server rejected status update');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update trip status: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: const Color(0xFF4CAF50), size: 48.sp),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Trip Completed!',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Great job! The ride has been successfully completed and the user has been billed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    context.pop(); // Dismiss Dialog
                    context.pop(); // Back to Home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.white,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Dashboard',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // Google Map Screen
            Positioned.fill(
              bottom: 260.h,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.4279613, -122.0857496),
                  zoom: 12,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (!_isLoading) {
                    _fitMapBounds();
                  }
                },
                polylines: _polylines,
                markers: _markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
              ),
            ),

            // Premium Floating Back Button
            Positioned(
              top: 48.h,
              left: 20.w,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 14.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Premium Floating Center Map Button
            Positioned(
              top: 48.h,
              right: 20.w,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _fitMapBounds,
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.gps_fixed_rounded, color: AppColors.gold, size: 18.sp),
                  ),
                ),
              ),
            ),

            // Bottom Trip Details Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 280.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28.r),
                    topRight: Radius.circular(28.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Destination Address / Status Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.trip.reference ?? 'Active Assignment',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        if (_distance != null && _duration != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '$_distance • $_duration',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Route details card
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.my_location_rounded, size: 12.sp, color: Colors.blue),
                              Container(width: 1.5.w, height: 16.h, color: AppColors.dividerGray),
                              Icon(Icons.circle, size: 8.sp, color: AppColors.gold),
                              Container(width: 1.5.w, height: 16.h, color: AppColors.dividerGray),
                              Icon(Icons.location_on_rounded, size: 12.sp, color: Colors.red),
                            ],
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  cleanLocationName(widget.trip.pickupLocation ?? 'Pickup'),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  cleanLocationName(widget.trip.dropoffLocation ?? 'Destination'),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Active Action Button
                    _buildActionButton(),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_tripStatus == TripStatus.confirmed || _tripStatus == TripStatus.pending) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                final passengerId = widget.trip.userId;
                if (passengerId != null) {
                  final title = 'Driver has arrived! 📍';
                  final body = 'Your driver has reached your pickup location.';
                  
                  ref.read(notificationRepositoryProvider).insert(
                    userId: passengerId,
                    title: title,
                    body: body,
                    type: 'booking',
                  ).catchError((e) => debugPrint('Error: $e'));

                  PushNotificationService().sendPushNotification(
                    recipientUserId: passengerId,
                    title: title,
                    body: body,
                  ).catchError((e) => debugPrint('Push Error: $e'));
                }
                _updateStatus('arrived', TripStatus.arrived);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCharcoal,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Reach to passenger',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            height: 50.h,
            width: 50.h,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: IconButton(
              onPressed: () {
                context.push(
                  '/chat/${widget.trip.id}',
                  extra: {'otherName': 'Passenger'},
                );
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold, size: 22.sp),
              tooltip: 'Chat',
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            height: 50.h,
            width: 50.h,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: IconButton(
              onPressed: _launchNavigation,
              icon: Icon(Icons.navigation_outlined, color: AppColors.gold, size: 24.sp),
              tooltip: 'Navigate',
            ),
          ),
        ],
      );
    } else if (_tripStatus == TripStatus.arrived) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                final passengerId = widget.trip.userId;
                if (passengerId != null) {
                  final title = 'Ride started! 🚗';
                  final body = 'You are now heading to your destination.';
                  
                  ref.read(notificationRepositoryProvider).insert(
                    userId: passengerId,
                    title: title,
                    body: body,
                    type: 'booking',
                  ).catchError((e) => debugPrint('Error inserting user notification DB: $e'));

                  PushNotificationService().sendPushNotification(
                    recipientUserId: passengerId,
                    title: title,
                    body: body,
                  ).catchError((e) => debugPrint('Error sending push: $e'));
                }
                _updateStatus('in_progress', TripStatus.inProgress);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.white,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Passenger Pickup',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            height: 50.h,
            width: 50.h,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: IconButton(
              onPressed: () {
                context.push(
                  '/chat/${widget.trip.id}',
                  extra: {'otherName': 'Passenger'},
                );
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold, size: 22.sp),
              tooltip: 'Chat',
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            height: 50.h,
            width: 50.h,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: IconButton(
              onPressed: _launchNavigation,
              icon: Icon(Icons.navigation_outlined, color: AppColors.gold, size: 24.sp),
              tooltip: 'Navigate',
            ),
          ),
        ],
      );
    } else if (_tripStatus == TripStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
                final passengerId = widget.trip.userId;
                final driverId = widget.trip.driverId ?? Supabase.instance.client.auth.currentUser?.id;
                
                final title = 'Ride Completed! 🎉';
                final body = 'The trip has been successfully completed.';
                
                // 1. Notify Passenger
                if (passengerId != null) {
                  ref.read(notificationRepositoryProvider).insert(
                    userId: passengerId, title: title, body: body, type: 'booking',
                  ).catchError((e) => debugPrint('Error: $e'));

                  PushNotificationService().sendPushNotification(
                    recipientUserId: passengerId, title: title, body: body,
                  ).catchError((e) => debugPrint('Push Error: $e'));
                }
                
                // 2. Notify Driver
                if (driverId != null) {
                  ref.read(notificationRepositoryProvider).insert(
                    userId: driverId, title: title, body: body, type: 'booking',
                  ).catchError((e) => debugPrint('Error: $e'));

                  PushNotificationService().sendPushNotification(
                    recipientUserId: driverId, title: title, body: body,
                  ).catchError((e) => debugPrint('Push Error: $e'));
                }
                
                // 3. Notify Admins
                try {
                  final adminRes = await Supabase.instance.client.from('profiles')
                      .select('id')
                      .ilike('username', '%admin%');
                  for (var admin in adminRes) {
                    final adminId = admin['id'];
                    ref.read(notificationRepositoryProvider).insert(
                      userId: adminId, title: 'Trip Completed', body: 'Trip ${widget.trip.reference ?? widget.trip.id} completed.', type: 'booking',
                    ).catchError((e) => debugPrint('Error: $e'));

                    PushNotificationService().sendPushNotification(
                      recipientUserId: adminId, title: 'Trip Completed', body: 'Trip ${widget.trip.reference ?? widget.trip.id} completed.',
                    ).catchError((e) => debugPrint('Push Error: $e'));
                  }
                } catch (e) {
                  debugPrint('Error notifying admins: $e');
                }

                _updateStatus('completed', TripStatus.past);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.white,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Complete Ride',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            height: 50.h,
            width: 50.h,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: IconButton(
              onPressed: () {
                context.push(
                  '/chat/${widget.trip.id}',
                  extra: {'otherName': 'Passenger'},
                );
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold, size: 22.sp),
              tooltip: 'Chat',
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            height: 50.h,
            width: 50.h,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: IconButton(
              onPressed: _launchNavigation,
              icon: Icon(Icons.navigation_outlined, color: AppColors.gold, size: 24.sp),
              tooltip: 'Navigate',
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Trip Completed',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }
  }
}
