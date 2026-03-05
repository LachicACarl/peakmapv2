import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  Timer? _gpsTimer;
  WebSocketChannel? _wsChannel;
  Position? _currentPosition;
  bool _isTracking = false;
  String _statusMessage = "Initializing...";

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
    NotificationService.notificationStream.listen((data) {
      if (mounted) {
        NotificationService.showSnackbar(
          context,
          'Driver notification: ${data.toString()}',
          backgroundColor: Colors.blue,
        );
      }
    });
  }

  /// Check and request location permissions
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "Location services are disabled";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
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

    _startTracking();
  }

  /// Start GPS tracking and sending updates to backend
  void _startTracking() {
    setState(() {
      _isTracking = true;
      _statusMessage = "Connecting to WebSocket...";
    });

    // Connect to WebSocket
    try {
      final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/driver/${widget.driverId}'),
      );

      setState(() {
        _statusMessage = "WebSocket connected - Tracking active";
      });

      // Send GPS update every 5 seconds
      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          setState(() {
            _currentPosition = position;
          });

          // Update camera position
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
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
        } catch (e) {
          setState(() {
            _statusMessage = "Error: $e";
          });
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = "WebSocket connection failed: $e";
        _isTracking = false;
      });
    }
  }

  /// Stop GPS tracking
  void _stopTracking() {
    _gpsTimer?.cancel();
    _wsChannel?.sink.close();
    setState(() {
      _isTracking = false;
      _statusMessage = "Tracking stopped";
    });
  }

  /// Show dialog to enter ride ID for cash payment confirmation
  void _showCashPaymentDialog() {
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
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.5547, 121.0244), // EDSA default
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          
          // Status Card at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status header
                    Row(
                      children: [
                        PulseAnimation(
                          pulseColor: _isTracking ? Colors.green : Colors.red,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _isTracking ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTracking ? '📡 Live Broadcasting' : '⏸️ Not Tracking',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _statusMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // GPS coordinates when available
                    if (_currentPosition != null) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.grey.withOpacity(0.3),
                        height: 0,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Latitude',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentPosition!.latitude.toStringAsFixed(5),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Longitude',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentPosition!.longitude.toStringAsFixed(5),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Speed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_currentPosition!.speed.toStringAsFixed(1)} m/s',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
