import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  MapController? _mapController;
  Timer? _updateTimer;
  Timer? _trackingRefreshTimer;
  WebSocketChannel? _wsChannel;
  
  // Map markers
  final List<Marker> _markers = [];
  
  // Bus location
  double? _busLat;
  double? _busLng;
  
  // ETA info
  String _etaText = "Calculating...";
  String _distanceText = "";
  String _arrivalText = "--:--";
  String _driverLocationText = "Waiting for driver GPS";
  String _currentStation = "";
  String _destinationStation = "";
  int? _stopsRemaining;
  String _rideStatus = "ongoing";
  double? _fareAmount;
  
  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _refreshTrackingData();
    _startTrackingDataRefresh();
    _startRideStatusCheck();
    _subscribeToNotifications();
    _listenToNotifications();
  }

  void _startTrackingDataRefresh() {
    _trackingRefreshTimer?.cancel();
    _trackingRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshTrackingData();
    });
  }

  String _formatClock(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _refreshTrackingData() async {
    try {
      final gpsData = await ApiService.getLatestGPS(widget.driverId);
      final gpsLat = (gpsData['latitude'] as num?)?.toDouble();
      final gpsLng = (gpsData['longitude'] as num?)?.toDouble();

      if (gpsLat != null && gpsLng != null) {
        if (!mounted) return;
        setState(() {
          _busLat = gpsLat;
          _busLng = gpsLng;
          _driverLocationText = '${gpsLat.toStringAsFixed(5)}, ${gpsLng.toStringAsFixed(5)}';
          _updateMarkers();
        });
      }

      final etaData = await ApiService.getETA(
        driverId: widget.driverId,
        stationId: widget.stationId,
      );

      final stationEtaText = (etaData['eta_text'] as String?)?.trim();
      final etaMinutes = (etaData['eta_minutes'] as num?)?.toDouble();
      final stopsRemaining = (etaData['stops_remaining'] as num?)?.toInt();
      final currentStation = (etaData['current_station'] as String?) ?? '';
      final destinationStation =
          (etaData['destination_station'] as String?) ??
          (etaData['station_name'] as String?) ??
          '';
      final distanceKm = (etaData['distance_km'] as num?)?.toDouble();

      final etaDuration = (etaData['duration'] as String?) ?? 'N/A';
      final etaDistance = (etaData['distance'] as String?) ?? 'N/A';
      final etaSeconds = (etaData['seconds'] as num?)?.toInt() ?? 0;

      if (!mounted) return;
      setState(() {
        _etaText = stationEtaText != null && stationEtaText.isNotEmpty
            ? stationEtaText
            : (etaDuration == 'N/A' ? 'ETA unavailable' : etaDuration);

        _distanceText = distanceKm != null
            ? 'Distance: ${distanceKm.toStringAsFixed(1)} km • Driver: $_driverLocationText'
            : (etaDistance == 'N/A'
                ? 'Driver: $_driverLocationText'
                : 'Distance: $etaDistance • Driver: $_driverLocationText');

        _stopsRemaining = stopsRemaining;
        _currentStation = currentStation;
        _destinationStation = destinationStation;

        if (etaMinutes != null && etaMinutes > 0) {
          _arrivalText = _formatClock(
            DateTime.now().add(Duration(minutes: etaMinutes.ceil())),
          );
        } else if (etaSeconds > 0) {
          _arrivalText = _formatClock(DateTime.now().add(Duration(seconds: etaSeconds)));
        }
      });
    } catch (_) {
      // Keep last known tracking values when refresh fails.
    }
  }

  String _stationProgressText() {
    if (_currentStation.isEmpty && _destinationStation.isEmpty) {
      return '';
    }

    final fromText = _currentStation.isEmpty ? 'Current station...' : _currentStation;
    final toText = _destinationStation.isEmpty ? 'Destination...' : _destinationStation;

    if (_stopsRemaining == null) {
      return '$fromText → $toText';
    }

    final stopsLabel = _stopsRemaining == 1 ? '1 stop left' : '${_stopsRemaining!} stops left';
    return '$fromText → $toText • $stopsLabel';
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

      if (_busLat != null && _busLng != null) {
        _driverLocationText = '${_busLat!.toStringAsFixed(5)}, ${_busLng!.toStringAsFixed(5)}';
      }
      
      // Update ETA and distance if provided
      if (data.containsKey('eta')) {
        _etaText = data['eta'];
      }
      if (data.containsKey('distance')) {
        _distanceText = data['distance'];
      }
      
      // Update markers
      _updateMarkers();
      
      // Move map to bus location
      if (_mapController != null && _busLat != null && _busLng != null) {
        _mapController!.move(
          LatLng(_busLat!, _busLng!),
          15.0,
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

  /// Update map markers with improved design (bus and station)
  void _updateMarkers() {
    _markers.clear();
    
    // Add enhanced bus marker
    if (_busLat != null && _busLng != null) {
      _markers.add(
        Marker(
          width: 100,
          height: 100,
          point: LatLng(_busLat!, _busLng!),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ETA badge above bus
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _etaText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Bus icon with shadow
              Stack(
                alignment: Alignment.center,
                children: [
                  // Shadow circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  // White background circle
                  Container(
                    width: 44,
                    height: 44,
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
                  // Blue circle with bus icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2196F3),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
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
    _trackingRefreshTimer?.cancel();
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
                // OpenStreetMap
                FlutterMap(
                  mapController: _mapController ??= MapController(),
                  options: MapOptions(
                    initialCenter: _busLat != null && _busLng != null
                        ? LatLng(_busLat!, _busLng!)
                        : const LatLng(14.5547, 121.0244), // EDSA default
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.peakmap.app',
                    ),
                    MarkerLayer(
                      markers: _markers,
                    ),
                  ],
                ),
                
                // Status banner at top
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚌 Tracking Your Bus',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _stationProgressText().isNotEmpty
                                    ? _stationProgressText()
                                    : (_distanceText.isNotEmpty ? _distanceText : 'Connecting...'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Real-time indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.circle, size: 8, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Enhanced ETA Card at bottom
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: FareInfoCard(
                      status: _rideStatus,
                      etaText: _arrivalText == '--:--' ? _etaText : '$_etaText • Arrive $_arrivalText',
                      distanceText: _stationProgressText().isEmpty
                          ? _distanceText
                          : '${_stationProgressText()}\n$_distanceText',
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
                ),
              ],
            ),
    );
  }
}
