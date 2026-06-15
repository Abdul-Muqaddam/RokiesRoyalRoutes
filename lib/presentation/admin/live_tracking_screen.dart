import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

// Simple state model for tracking
class TrackingState {
  final LatLng? position;
  final String status;
  TrackingState({this.position, this.status = 'connecting'});
}

final trackingStateProvider = StateNotifierProvider.family.autoDispose<TrackingNotifier, TrackingState, String>((ref, driverId) {
  return TrackingNotifier(driverId);
});

class TrackingNotifier extends StateNotifier<TrackingState> {
  final String driverId;
  RealtimeChannel? _channel;
  final _supabase = Supabase.instance.client;

  TrackingNotifier(this.driverId) : super(TrackingState()) {
    _init();
  }

  void _init() async {
    // Initial fetch
    try {
      final res = await _supabase
          .from('driver_status')
          .select('lat, lng')
          .eq('driver_id', driverId)
          .maybeSingle();
      
      if (res != null) {
        state = TrackingState(
          position: LatLng((res['lat'] as num).toDouble(), (res['lng'] as num).toDouble()),
          status: state.status,
        );
      }
    } catch (e) {
      debugPrint('❌ [MAP] Initial Fetch Error: $e');
    }

    // Single Channel for everything
    _channel = _supabase.channel('tracking-$driverId');

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'driver_status',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'driver_id',
        value: driverId,
      ),
      callback: (payload) {
        final data = payload.newRecord;
        if (data['lat'] != null && data['lng'] != null) {
          state = TrackingState(
            position: LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble()),
            status: state.status,
          );
        }
      },
    ).subscribe((status, [error]) {
      debugPrint('📡 [MAP] Channel Status: ${status.name} ${error ?? ''}');
      state = TrackingState(position: state.position, status: status.name.toLowerCase());
    });
  }

  @override
  void dispose() {
    if (_channel != null) _supabase.removeChannel(_channel!);
    super.dispose();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String driverId;
  final String driverName;

  const LiveTrackingScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  bool _isFirstLoad = true;

  Widget _buildConnectionStatus(String status) {
    Color color;
    switch (status) {
      case 'subscribed': color = Colors.greenAccent; break;
      case 'error':      color = Colors.redAccent;   break;
      case 'closed':     color = Colors.redAccent; break;
      default:           color = Colors.grey;         break;
    }

    return Tooltip(
      message: 'Channel Status: $status',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            SizedBox(width: 6.w),
            Text(
              'LIVE',
              style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingStateProvider(widget.driverId));

    final markers = <Marker>{};
    if (trackingState.position != null) {
      markers.add(
        Marker(
          markerId: MarkerId(widget.driverId),
          position: trackingState.position!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: widget.driverName, snippet: 'Current Location'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking: ${widget.driverName}',
              style: TextStyle(color: AppColors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              'Live Updates via Supabase',
              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
            ),
          ],
        ),
        actions: [
          _buildConnectionStatus(trackingState.status),
          SizedBox(width: 16.w),
        ],
      ),
      body: Stack(
        children: [
          // The Map is now static in the build tree to prevent unnecessary rebuilds
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 2),
            onMapCreated: (controller) {
              _mapController = controller;
              if (trackingState.position != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(trackingState.position!, 16),
                );
                _isFirstLoad = false;
              }
            },
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
          ),

          // Listening to updates without triggering a full screen rebuild
          Consumer(
            builder: (context, ref, child) {
              ref.listen(trackingStateProvider(widget.driverId), (previous, next) {
                if (next.position != null && _mapController != null) {
                  if (_isFirstLoad) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(next.position!, 16),
                    );
                    _isFirstLoad = false;
                  } else {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(next.position!),
                    );
                  }
                }
              });
              return const SizedBox.shrink();
            },
          ),
          
          if (trackingState.position == null && trackingState.status == 'connecting')
            const Center(child: CircularProgressIndicator()),
          
          if (trackingState.status == 'error')
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.8),
                child: const Text('Connection Error. Please check Supabase Realtime settings.', style: TextStyle(color: Colors.white)),
              ),
            ),
          
          // Floating Info Overlay
          Positioned(
            bottom: 24.h,
            left: 16.w,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.gps_fixed, color: Colors.green),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Live Tracking Active',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                        ),
                        Text(
                          'Driver is currently on the move',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (trackingState.position != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(trackingState.position!, 16),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: const Text('Center'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
