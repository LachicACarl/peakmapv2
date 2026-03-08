import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/api_service.dart';
import './passenger_map.dart';
import './passenger_balance_view.dart';

class PassengerDashboard extends StatefulWidget {
  final int passengerId;
  
  const PassengerDashboard({Key? key, required this.passengerId}) : super(key: key);

  @override
  State<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard> {
  bool _showLocationBanner = true;
  int? _selectedStationId;
  String? _selectedStationName;
  int? _selectedDriverId;
  bool _isLoading = false;
  DateTime? _departureTime;
  DateTime? _estimatedArrivalTime;
  String _durationBadge = '00:00:00';
  String _etaSummary = 'Tap card on entry to start';
  String _driverLocationSummary = 'Driver location unavailable';
  double _estimatedFarePhp = 0.0;
  String? _entryCardUid;
  
  // OpenStreetMap
  MapController? _mapController;
  Position? _currentPosition;
  final List<Marker> _markers = [];
  bool _isLoadingMap = true;
  
  // Default location (Manila)
  static const LatLng _defaultLocation = LatLng(14.5995, 120.9842);

  static const String _phpCurrencyCode = 'PHP';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '00:00';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not started';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = weekdays[value.weekday - 1];
    final month = months[value.month - 1];
    return '$day, ${value.day} $month';
  }

  String _formatDurationFromSeconds(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final hours = (safeSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((safeSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  Future<void> _refreshTripPreview({
    required int driverId,
    required int stationId,
  }) async {
    try {
      final gps = await ApiService.getLatestGPS(driverId);
      final eta = await ApiService.getETA(driverId: driverId, stationId: stationId);

      final lat = (gps['latitude'] as num?)?.toDouble();
      final lng = (gps['longitude'] as num?)?.toDouble();

      final etaSeconds = (eta['seconds'] as num?)?.toInt() ?? 0;
      final etaDuration = (eta['duration'] as String?) ?? 'N/A';
      final etaDistance = (eta['distance'] as String?) ?? 'N/A';
      final hasEta = etaSeconds > 0;

      if (!mounted) return;

      setState(() {
        _driverLocationSummary = (lat != null && lng != null)
            ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
            : 'Driver location unavailable';
        _etaSummary = etaDuration == 'N/A'
            ? 'ETA unavailable'
            : '$etaDuration • $etaDistance';
        if (hasEta) {
          _durationBadge = _formatDurationFromSeconds(etaSeconds);
          _estimatedArrivalTime = DateTime.now().add(Duration(seconds: etaSeconds));
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _etaSummary = 'ETA unavailable';
      });
    }
  }

  /// Initialize map with current location and nearby stations
  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadNearbyStations();
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingMap = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingMap = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingMap = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingMap = false;
      });

      // Move map to current location
      if (_mapController != null) {
        _mapController!.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingMap = false);
    }
  }

  /// Load nearby stations and add as markers
  Future<void> _loadNearbyStations() async {
    try {
      final stations = await ApiService.getStations();
      
      for (var station in stations) {
        final stationData = station as Map<String, dynamic>;
        final lat = stationData['latitude'];
        final lng = stationData['longitude'];
        
        if (lat != null && lng != null) {
          _markers.add(
            Marker(
              width: 40,
              height: 40,
              point: LatLng(lat.toDouble(), lng.toDouble()),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStationId = stationData['id'];
                    _selectedStationName = stationData['name'];
                    _selectedDriverId = stationData['driver_id'];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${stationData['name']}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.orange,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading stations: $e');
    }
  }

  Future<String?> _requestEntryCardUid() async {
    final controller = TextEditingController(text: _entryCardUid ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tap Card On Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter or scan the card UID used for bus entry.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Card UID',
                hintText: 'e.g. 1603310630',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.of(dialogContext).pop(trimmed.isEmpty ? null : trimmed);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    controller.dispose();
    return value;
  }

  /// Show station picker dialog
  Future<void> _showStationPicker() async {
    try {
      final stations = await ApiService.getStations();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📍 Select Departure Station'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  stations.length,
                  (index) {
                    final station = stations[index] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(station['name'] ?? 'Station'),
                      subtitle: Text('${station['latitude']}, ${station['longitude']}'),
                      onTap: () {
                        setState(() {
                          _selectedStationId = station['id'];
                          _selectedStationName = station['name'];
                          _selectedDriverId = station['driver_id']; // If available
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: ${station['name']}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stations: $e')),
        );
      }
    }
  }

  /// Create ride and start tracking
  Future<void> _startTrackingBus() async {
    if (_selectedStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a station first')),
      );
      return;
    }

    final cardUid = await _requestEntryCardUid();
    if (!mounted) return;

    if (cardUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card tap is required to start the trip')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requestedDriverId = _selectedDriverId ?? 1;

      final tapInResult = await ApiService.tapInPassenger(
        userId: widget.passengerId.toString(),
        busId: requestedDriverId.toString(),
        driverId: requestedDriverId.toString(),
        stationId: _selectedStationId!,
        cardUid: cardUid,
      );

      if (tapInResult['success'] != true) {
        final errorMessage = tapInResult['error']?.toString() ??
            tapInResult['message']?.toString() ??
            'Tap-in failed';
        throw Exception(errorMessage);
      }

      final result = await ApiService.createRide(
        passengerId: widget.passengerId,
        stationId: _selectedStationId!,
        driverId: requestedDriverId,
      );

      final resolvedDriverId = (result['driver_id'] as num?)?.toInt() ?? _selectedDriverId ?? 1;
      final resolvedRideId = (result['ride_id'] as num?)?.toInt() ?? (result['id'] as num?)?.toInt() ?? 1;
      final fareFromApi = (result['fare_amount'] as num?)?.toDouble() ?? 0.0;

      setState(() {
        _selectedDriverId = resolvedDriverId;
        _departureTime = DateTime.now();
        _estimatedArrivalTime = _departureTime;
        _durationBadge = '00:00:00';
        _estimatedFarePhp = fareFromApi;
        _etaSummary = 'Calculating ETA...';
        _driverLocationSummary = 'Locating driver...';
        _entryCardUid = cardUid;
      });

      final tapBalance = (tapInResult['current_balance'] as num?)?.toDouble();
      final balanceText = tapBalance == null ? '' : ' • Balance ₱${tapBalance.toStringAsFixed(2)}';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entry granted for card $cardUid$balanceText'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _refreshTripPreview(
        driverId: resolvedDriverId,
        stationId: _selectedStationId!,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PassengerMapScreen(
              driverId: resolvedDriverId,
              stationId: _selectedStationId!,
              rideId: resolvedRideId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Google Map Section with Location Banner
            Stack(
              children: [
                // OpenStreetMap - No API key needed!
                SizedBox(
                  height: 300,
                  child: _isLoadingMap
                      ? Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController ??= MapController(),
                          options: MapOptions(
                            initialCenter: _currentPosition != null
                                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                : _defaultLocation,
                            initialZoom: 14.0,
                            minZoom: 5.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.peakmap.app',
                            ),
                            MarkerLayer(
                              markers: [
                                // Current location marker
                                if (_currentPosition != null)
                                  Marker(
                                    width: 40,
                                    height: 40,
                                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 40,
                                    ),
                                  ),
                                // Station markers
                                ..._markers,
                              ],
                            ),
                          ],
                        ),
                ),
                // Enable location banner
                if (_showLocationBanner && _currentPosition == null)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enable live location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'To see nearby stations and track buses',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _showLocationBanner = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                // Station info overlay (when station is selected)
                if (_selectedStationName != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Station',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _selectedStationName!,
                                  style: const TextStyle(
                                    fontSize: 16,
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
              ],
            ),

            const SizedBox(height: 20),

            // Dark Trip Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1f2e),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Departure
                        _buildTimeInfo(
                          _formatTime(_departureTime),
                          'Departure',
                          _formatDate(_departureTime),
                        ),
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFffd700),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _durationBadge,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // Arrival
                        _buildTimeInfo(
                          _formatTime(_estimatedArrivalTime),
                          'Arrival',
                          _formatDate(_estimatedArrivalTime),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTripDetail('1 adult'),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white24,
                        ),
                        _buildTripDetail('$_phpCurrencyCode  ₱${_estimatedFarePhp.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Station Selector Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showStationPicker,
                        icon: const Icon(Icons.location_on),
                        label: Text(
                          _selectedStationName ?? 'Select Station',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Track Bus Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _startTrackingBus,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.directions_bus),
                        label: Text(
                          _isLoading ? 'Starting...' : '💳 Tap Card & Track Bus',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Your Transport Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Transport',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '3D',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3D Bus Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1f2e),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Bus illustration
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_bus,
                            size: 80,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'DAMA',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tap to view overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Tap to view 3D bus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Trip Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildDetailChip('Driver #${_selectedDriverId ?? '--'}', Icons.person_pin_circle),
                  _buildDetailChip(_etaSummary, Icons.schedule),
                  _buildDetailChip(_driverLocationSummary, Icons.location_on),
                  _buildDetailChip(
                    _entryCardUid == null ? 'Card not tapped' : 'Card $_entryCardUid',
                    Icons.contactless,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // View Balance & View all trips buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // View Balance Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PassengerBalanceView(
                              userId: widget.passengerId.toString(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text(
                        'View Balance & History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // View all trips button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to trips list
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'View all trips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String time, String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetail(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
