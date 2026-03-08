import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_widgets.dart';
import 'cash_confirm_screen.dart';

/// Driver Map Screen - Sends live GPS data to backend
/// 
/// Features:
/// - Live GPS tracking every 5 seconds
/// - Displays driver's current location on map
/// - Automatically updates backend with GPS coordinates
class DriverMapScreen extends StatefulWidget {
  final int driverId;
  
  const DriverMapScreen({
    Key? key,
    required this.driverId,
  }) : super(key: key);

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  MapController? _mapController;
  Timer? _gpsTimer;
  WebSocketChannel? _wsChannel;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  Position? _currentPosition;
  bool _isTracking = false;
  String _statusMessage = "Initializing...";
  
  // Route history & ETA features
  List<LatLng> _routeHistory = [];
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  Map<int, dynamic> _activeRides = {};
  String? _etaToNextStop;
  bool _geoFenceTriggered = false;
  static const double GEOFENCE_RADIUS_METERS = 100; // Alert when 100m from station

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _subscribeToNotifications();
  }

  /// Subscribe to driver-specific notifications
  void _subscribeToNotifications() {
    NotificationService.subscribeToDriver(widget.driverId);
    
    // Listen for notifications
    _notificationSubscription?.cancel();
    _notificationSubscription = NotificationService.notificationStream.listen((data) {
      if (!mounted) return;
      NotificationService.showSnackbar(
        context,
        'Driver notification: ${data.toString()}',
        backgroundColor: Colors.blue,
      );
    });
  }

  /// Load active rides to show destinations on map
  Future<void> _loadActiveRides() async {
    try {
      final rides = await ApiService.getDriverRides(widget.driverId);
      if (mounted) {
        setState(() {
          _activeRides = {for (var r in rides) r['station_id']: r};
        });
      }
    } catch (e) {
      // Silently fail - rides update automatically
    }
  }

  /// Calculate distance between two points (in meters)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - 
        cos((lat2 - lat1) * p) / 2 + 
        cos(lat1 * p) * cos(lat2 * p) * 
        (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  /// Check geofencing - alert if near destination station
  Future<void> _checkGeofencing(Position position) async {
    if (_activeRides.isEmpty) return;
    
    for (var ride in _activeRides.values) {
      final stationId = ride['station_id'];
      try {
        final eta = await ApiService.getETA(
          driverId: widget.driverId,
          stationId: stationId,
        );
        if (!mounted) return;
        
        final distance = eta['distance_to_station'] as double?;
        if (distance != null && distance < GEOFENCE_RADIUS_METERS && !_geoFenceTriggered) {
          _geoFenceTriggered = true;
          NotificationService.showSnackbar(
            context,
            '🎯 Arriving at ${ride['station_name']} - ${distance.toStringAsFixed(0)}m away',
            backgroundColor: Colors.green,
          );
          // Reset after 2 minutes
          await Future.delayed(const Duration(minutes: 2));
          if (!mounted) return;
          _geoFenceTriggered = false;
        }
      } catch (e) {
        // Silently fail
      }
    }
  }

  /// Check and request location permissions
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "Location services are disabled";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = "Location permissions are denied";
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = "Location permissions are permanently denied";
      });
      return;
    }

    if (!mounted) return;
    _startTracking();
  }

  /// Start GPS tracking and sending updates to backend
  void _startTracking() {
    if (!mounted) return;

    setState(() {
      _isTracking = true;
      _statusMessage = "Connecting to WebSocket...";
    });

    _loadActiveRides(); // Load rides at start

    // Connect to WebSocket
    try {
      final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/driver/${widget.driverId}'),
      );

      if (!mounted) return;
      setState(() {
        _statusMessage = "WebSocket connected - Tracking active";
      });

      // Send GPS update every 5 seconds
      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          if (!mounted) return;
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          if (!mounted) return;

          setState(() {
            _currentPosition = position;
            
            // Add to route history
            _routeHistory.add(LatLng(position.latitude, position.longitude));
            
            // Update polyline with better styling
            if (_routeHistory.length >= 2) {
              _polylines = [
                Polyline(
                  points: _routeHistory,
                  color: const Color(0xFF2196F3), // Material blue
                  strokeWidth: 6.0,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2.0,
                ),
              ];
            }
          });

          // Update camera position
          if (_mapController != null) {
            _mapController!.move(
              LatLng(position.latitude, position.longitude),
              14.0,
            );
          }

          // Send GPS data via WebSocket
          if (_wsChannel != null) {
            final gpsData = {
              "latitude": position.latitude,
              "longitude": position.longitude,
              "speed": position.speed,
              "timestamp": DateTime.now().toIso8601String(),
            };

            _wsChannel!.sink.add(jsonEncode(gpsData));

            if (!mounted) return;
            setState(() {
              _statusMessage =
                  "📡 Live broadcasting - Speed: ${position.speed.toStringAsFixed(1)} m/s";
            });
          }

          // Also send to backend HTTP (for logging purposes)
          await ApiService.updateGPS(
            driverId: widget.driverId,
            latitude: position.latitude,
            longitude: position.longitude,
            speed: position.speed,
          );
          if (!mounted) return;
          
          // Check geofencing for destination alerts
          await _checkGeofencing(position);
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _statusMessage = "Error: $e";
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "WebSocket connection failed: $e";
        _isTracking = false;
      });
    }
  }

  /// Manually refresh GPS location
  Future<void> _refreshLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
        _statusMessage = "📍 Location manually refreshed";
      });

      if (_mapController != null) {
        _mapController!.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
      }

      // Update backend
      await ApiService.updateGPS(
        driverId: widget.driverId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Location refreshed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to refresh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Stop GPS tracking
  void _stopTracking() {
    _gpsTimer?.cancel();
    _wsChannel?.sink.close();
    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _statusMessage = "Tracking stopped";
    });
  }

  /// Show dialog to enter ride ID for cash payment confirmation
  void _showCashPaymentDialog() {
    if (!mounted) return;
    final TextEditingController rideIdController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💵 Confirm Cash Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the Ride ID to confirm cash payment:'),
            const SizedBox(height: 16),
            TextField(
              controller: rideIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ride ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rideId = int.tryParse(rideIdController.text);
              if (rideId != null) {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashConfirmScreen(rideId: rideId),
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _wsChannel?.sink.close();
    _notificationSubscription?.cancel();
    
    // Unsubscribe from notifications
    NotificationService.unsubscribeFromDriver(widget.driverId);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Live Map"),
        backgroundColor: Colors.blue,
        actions: [
          // Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
            tooltip: 'Manually refresh location',
          ),
          // Play/Pause tracking
          IconButton(
            icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
            onPressed: _isTracking ? _stopTracking : _startTracking,
            tooltip: _isTracking ? 'Pause tracking' : 'Start tracking',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCashPaymentDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.payment),
        label: const Text('💵 Cash Payment'),
      ),
      body: Stack(
        children: [
          // OpenStreetMap with polylines and current location
          FlutterMap(
            mapController: _mapController ??= MapController(),
            options: const MapOptions(
              initialCenter: LatLng(14.5547, 121.0244), // EDSA default
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.peak_map_mobile',
              ),
              PolylineLayer(
                polylines: _polylines,
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse effect outer circle
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          ),
                          // Middle circle
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          // Icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2196F3),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Status Card at bottom with improved design
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              elevation: 12,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.blue.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status header with better design
                      Row(
                        children: [
                          // Animated status indicator
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _isTracking ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isTracking ? Colors.green : Colors.grey).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: _isTracking
                                ? const Icon(Icons.radio_button_checked, size: 12, color: Colors.white)
                                : const Icon(Icons.radio_button_unchecked, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isTracking ? '🚌 Live Tracking Active' : '⏸️ Tracking Paused',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _isTracking ? Colors.green.shade700 : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _statusMessage,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Route statistics with improved design
                      if (_routeHistory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.shade300,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.route,
                              value: '${_routeHistory.length}',
                              label: 'Route Points',
                              color: const Color(0xFF2196F3),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            _buildStatItem(
                              icon: Icons.place,
                              value: '${_activeRides.length}',
                              label: 'Active Stops',
                              color: const Color(0xFFFF9800),
                            ),
                          ],
                        ),
                      ],
                    
                      // GPS coordinates with improved design
                      if (_currentPosition != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.grey.shade300,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildCoordItem(
                                    label: 'Latitude',
                                    value: _currentPosition!.latitude.toStringAsFixed(5),
                                    icon: Icons.south,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildCoordItem(
                                    label: 'Longitude',
                                    value: _currentPosition!.longitude.toStringAsFixed(5),
                                    icon: Icons.east,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.speed, size: 18, color: Color(0xFF2196F3)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Speed: ${_currentPosition!.speed.toStringAsFixed(1)} m/s',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ),  // Close Positioned widget
        ],
      ),
    );
  }

  // Helper method to build stat items
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // Helper method to build coordinate items
  Widget _buildCoordItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
