import 'package:flutter/material.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/services/vehicle_service.dart';
import '../../core/theme/app_theme.dart';

class VehiclesScreen extends StatefulWidget {
  @override
  _VehiclesScreenState createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Vehicles'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show loading spinner
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchVehicles,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_vehicles.isEmpty) {
      return Center(
        child: Text('No vehicles available'),
      );
    }

    // Show vehicles list
    return RefreshIndicator(
      onRefresh: _fetchVehicles,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          return VehicleCard(vehicle: _vehicles[index]);
        },
      ),
    );
  }
}

// ── Vehicle Card ──
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Image.network(
              vehicle.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.directions_car,
                    size: 60,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vehicle.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vehicle.vehicleType,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Description
                Text(
                  vehicle.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 12),

                // Capacity Row
                Row(
                  children: [
                    Icon(Icons.person_outline, 
                      size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${vehicle.passengerCapacity} passengers'),
                    SizedBox(width: 16),
                    Icon(Icons.luggage, 
                      size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${vehicle.luggageCapacity} bags'),
                  ],
                ),
                SizedBox(height: 12),

                // Divider
                Divider(),
                SizedBox(height: 8),

                // Price + Book Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From ${vehicle.currency} ${vehicle.basePrice}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${vehicle.currency} ${vehicle.pricePerKm}/km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to booking screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Book Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
