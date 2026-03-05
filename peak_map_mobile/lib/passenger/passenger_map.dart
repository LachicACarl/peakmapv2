import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_widgets.dart';
import 'payment_screen.dart';

/// Passenger Map Screen - Track bus in real-time
/// 
/// Features:
/// - Live bus tracking with moving marker
/// - Real-time ETA updates
/// - Destination station marker
/// - Distance and time to arrival
class PassengerMapScreen extends StatefulWidget {
  final int driverId;
  final int stationId;
  final int rideId;

  const PassengerMapScreen({
    Key? key,
    required this.driverId,
    required this.stationId,
    required this.rideId,
  }) : super(key: key);

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  GoogleMapController? _mapController;
  Timer? _updateTimer;
  WebSocketChannel? _wsChannel;
  
  // Map markers
  final Set<Marker> _markers = {};
  
  // Bus location
  double? _busLat;
  double? _busLng;
  
  // ETA info
  String _etaText = "Calculating...";
  String _distanceText = "";
  String _rideStatus = "ongoing";
  double? _fareAmount;
  
  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _startRideStatusCheck();
    _subscribeToNotifications();
    _listenToNotifications();
  }

  /// Subscribe to ride and driver notifications
  void _subscribeToNotifications() {
    NotificationService.subscribeToRide(widget.rideId);
    NotificationService.subscribeToDriver(widget.driverId);
  }

  /// Listen to notification stream for updates
  void _listenToNotifications() {
    NotificationService.notificationStream.listen((data) {
      // Handle notification tap/payload
      if (mounted) {
        NotificationService.showSnackbar(
          context,
          'Notification received: ${data.toString()}',
          backgroundColor: Colors.blue,
        );
      }
    });
  }

  /// Connect to WebSocket for real-time GPS updates
  void _connectWebSocket() {
    try {
      final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/passenger/${widget.driverId}'),
      );

      setState(() {
        _isLoading = false;
      });

      // Listen for GPS updates from driver
      _wsChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _updateBusPosition(data);
          } catch (e) {
            print('❌ Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          setState(() {
            _etaText = "Connection lost";
          });
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          setState(() {
            _etaText = "Disconnected";
          });
        },
      );
    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
      setState(() {
        _etaText = "Connection failed";
        _isLoading = false;
      });
    }
  }

  /// Update bus position from WebSocket data
  void _updateBusPosition(Map<String, dynamic> data) {
    setState(() {
      _busLat = data['latitude'];
      _busLng = data['longitude'];
      
      // Update ETA and distance if provided
      if (data.containsKey('eta')) {
        _etaText = data['eta'];
      }
      if (data.containsKey('distance')) {
        _distanceText = data['distance'];
      }
      
      // Update markers
      _updateMarkers();
      
      // Move camera to bus location
      if (_mapController != null && _busLat != null && _busLng != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_busLat!, _busLng!),
          ),
        );
      }
    });
  }

  /// Start periodic ride status check (for drop-off/missed detection)
  void _startRideStatusCheck() {
    // Check ride status every 10 seconds (less frequent than GPS)
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkRideStatus();
    });
  }

  /// Check ride status for drop-off or missed detection
  Future<void> _checkRideStatus() async {
    try {
      final statusData = await ApiService.checkRideStatus(widget.rideId);
      
      final status = statusData['status'];
      final fareAmount = statusData['fare_amount'];
      
      setState(() {
        if (fareAmount != null) {
          _fareAmount = fareAmount.toDouble();
        }
      });
      
      if (status == 'dropped') {
        setState(() {
          _rideStatus = 'dropped';
        });
        
        // Show notification
        if (mounted) {
          NotificationService.showSnackbar(
            context,
            "🎉 You've arrived! Fare: ₱${_fareAmount?.toStringAsFixed(2)}",
            backgroundColor: Colors.green,
          );
        }
        
        _showStatusDialog(
          title: "🎉 You've Arrived!",
          message: "You have reached your destination station.\n\nFare: ₱${_fareAmount?.toStringAsFixed(2) ?? 'N/A'}\n\nPlease proceed to payment.",
          color: Colors.green,
        );
        _updateTimer?.cancel();
        
        // Unsubscribe from topics
        NotificationService.unsubscribeFromRide(widget.rideId);
        NotificationService.unsubscribeFromDriver(widget.driverId);
        
      } else if (status == 'missed') {
        setState(() {
          _rideStatus = 'missed';
        });
        
        // Show notification
        if (mounted) {
          NotificationService.showSnackbar(
            context,
            "⚠️ Missed your stop! Please contact driver.",
            backgroundColor: Colors.orange,
          );
        }
        
        _showStatusDialog(
          title: "⚠️ Missed Stop!",
          message: "The bus passed your station. Please contact the driver.",
          color: Colors.orange,
        );
        _updateTimer?.cancel();
        
        // Unsubscribe from topics
        NotificationService.unsubscribeFromRide(widget.rideId);
        NotificationService.unsubscribeFromDriver(widget.driverId);
      }
    } catch (e) {
      // Silently handle errors for ride status check
    }
  }

  /// Update map markers (bus and station)
  void _updateMarkers() {
    _markers.clear();
    
    // Add bus marker
    if (_busLat != null && _busLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: LatLng(_busLat!, _busLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: '🚍 Your Bus',
            snippet: 'ETA: $_etaText',
          ),
        ),
      );
    }
    
    // TODO: Add station marker when station data is available
    // This would require fetching station details from the API
  }

  /// Show ride status dialog
  void _showStatusDialog({
    required String title,
    required String message,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor: color.withOpacity(0.1),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit tracking screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _wsChannel?.sink.close();
    
    // Unsubscribe from notifications
    NotificationService.unsubscribeFromRide(widget.rideId);
    NotificationService.unsubscribeFromDriver(widget.driverId);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Your Bus"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? PeakMapLoadingIndicator(
              message: "Connecting to your bus...",
              color: Colors.green,
            )
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _busLat != null && _busLng != null
                        ? LatLng(_busLat!, _busLng!)
                        : const LatLng(14.5547, 121.0244), // EDSA default
                    zoom: 15,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                
                // ETA Card at bottom
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: FareInfoCard(
                    status: _rideStatus,
                    etaText: _etaText,
                    distanceText: _distanceText,
                    fareAmount: _fareAmount,
                    paymentMethod: _rideStatus == 'dropped' ? 'Pending' : 'Processing',
                    showPaymentButton: _rideStatus == 'dropped' && _fareAmount != null,
                    onPaymentPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            rideId: widget.rideId,
                            fareAmount: _fareAmount!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
