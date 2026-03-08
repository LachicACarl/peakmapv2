import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/passenger_monitor_service.dart';
import './driver_alerts.dart';

class DriverDashboard extends StatefulWidget {
  final int driverId;
  
  const DriverDashboard({Key? key, required this.driverId}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isOnline = false;
  bool _isUpdating = false;
  int _alertsCount = 0;
  List<dynamic> _activeRides = [];
  bool _isLoadingRides = false;
  Timer? _refreshTimer;
  
  // Passenger monitoring
  List<Map<String, dynamic>> _passengerAlerts = [];
  StreamSubscription? _passengerMonitorSubscription;
  Set<int> _shownAlertIds = {};
  
  // Real-time passenger count from Supabase tap-in/tap-out
  int _livePassengerCount = 0;
  List<dynamic> _livePassengers = [];
  bool _isLoadingPassengerCount = false;

  @override
  void initState() {
    super.initState();
    _loadDriverStatus();  // Load current online/offline status from backend
    _loadAlertCount();
    _loadActiveRides();
    _loadLivePassengerCount();
    // Auto-refresh rides and passenger count every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadActiveRides();
      _loadLivePassengerCount();
    });
    
    // Monitor passenger issues
    _startPassengerMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _passengerMonitorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAlertCount() async {
    try {
      final alerts = await ApiService.getDriverAlerts(widget.driverId);
      if (!mounted) return;
      setState(() {
        _alertsCount = alerts.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alertsCount = 0;
      });
    }
  }

  /// Load current online/offline status from backend
  Future<void> _loadDriverStatus() async {
    try {
      final driverData = await ApiService.getDriverProfile(widget.driverId);
      if (!mounted) return;
      setState(() {
        _isOnline = driverData['is_online'] ?? false;
      });
    } catch (_) {
      // If error fetching status, default to offline
      if (!mounted) return;
      setState(() {
        _isOnline = false;
      });
    }
  }

  Future<void> _loadActiveRides() async {
    if (_isLoadingRides) return; // Prevent duplicate calls
    
    setState(() => _isLoadingRides = true);
    
    try {
      final rides = await ApiService.getDriverRides(widget.driverId);
      if (!mounted) return;
      setState(() {
        _activeRides = rides;
        _isLoadingRides = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeRides = [];
        _isLoadingRides = false;
      });
    }
  }

  /// Load real-time passenger count from Supabase tap-in/tap-out events
  Future<void> _loadLivePassengerCount() async {
    if (_isLoadingPassengerCount) return; // Prevent duplicate calls
    
    setState(() => _isLoadingPassengerCount = true);
    
    try {
      final data = await ApiService.getDriverPassengerCount(widget.driverId);
      if (!mounted) return;
      setState(() {
        _livePassengerCount = data['passenger_count'] ?? 0;
        _livePassengers = data['passengers'] ?? [];
        _isLoadingPassengerCount = false;
      });
    } catch (e) {
      print('Error loading passenger count: $e');
      if (!mounted) return;
      setState(() {
        _livePassengerCount = 0;
        _livePassengers = [];
        _isLoadingPassengerCount = false;
      });
    }
  }

  /// Start monitoring passenger no-shows and missed drop-offs
  void _startPassengerMonitoring() {
    _passengerMonitorSubscription = PassengerMonitorService.monitorPassengers(widget.driverId).listen(
      (alert) {
        if (!mounted) return;
        
        final alertId = '${alert['ride_id']}-${alert['type']}'.hashCode;
        
        // Show alert only once per issue
        if (!_shownAlertIds.contains(alertId)) {
          _shownAlertIds.add(alertId);
          
          setState(() {
            _passengerAlerts.add(alert);
          });
          
          // Show notification snackbar
          _showPassengerAlert(alert);
          
          // Remove after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _passengerAlerts.removeWhere((a) => a['ride_id'] == alert['ride_id']);
              });
            }
          });
        }
      },
    );
  }

  /// Display alert for passenger issue
  void _showPassengerAlert(Map<String, dynamic> alert) {
    final isNoShow = alert['type'] == 'no_show';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNoShow ? Icons.person_off : Icons.location_off,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isNoShow ? '⚠️ NO-SHOW PASSENGER' : '❌ MISSED DROP-OFF',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert['message'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Update driver online status - call backend API
  Future<void> _updateDriverStatus(bool isOnline) async {
    // Optimistically update UI
    setState(() {
      _isOnline = isOnline;
      _isUpdating = true;
    });
    
    try {
      await ApiService.updateDriverStatus(
        driverId: widget.driverId,
        isOnline: isOnline,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOnline ? '🟢 You are now ONLINE' : '🔴 You are now OFFLINE'),
            backgroundColor: isOnline ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() => _isOnline = !isOnline);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
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
            // Header with Online/Offline toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isOnline 
                    ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                    : [const Color(0xFF757575), const Color(0xFF424242)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${widget.driverId}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        // Online/Offline Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isOnline ? Icons.check_circle : Icons.cancel,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isOnline ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Toggle Switch Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Accept Passengers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Switch(
                            value: _isOnline,
                            onChanged: _isUpdating ? null : _updateDriverStatus,
                            activeColor: const Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Passenger Count Card (Live from Supabase Tap-In/Tap-Out) - MOVED TO TOP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _livePassengers.isEmpty ? null : () {
                      // Show passenger details modal
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Passengers Onboard ($_livePassengerCount)',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _livePassengers.length,
                                  itemBuilder: (context, index) {
                                    final passenger = _livePassengers[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '👤 ${passenger['user_id']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Boarded: Station ${passenger['boarding_station_id']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            'Tap-in time: ${passenger['tap_in_time'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PASSENGERS ONBOARD',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_livePassengerCount ${_livePassengerCount == 1 ? 'Passenger' : 'Passengers'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.tap_and_play,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live from tap-in/tap-out',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_livePassengers.isNotEmpty)
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Alerts Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverAlerts(driverId: widget.driverId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alerts & Notifications',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _alertsCount == 0 ? 'No Alerts' : '$_alertsCount Alerts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Passenger Issues Alert Section
            if (_passengerAlerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Show detailed alert list
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Passenger Issues (${_passengerAlerts.length})',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _passengerAlerts.length,
                                    itemBuilder: (context, index) {
                                      final alert = _passengerAlerts[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border(
                                            left: BorderSide(
                                              color: alert['type'] == 'no_show'
                                                ? Colors.orange
                                                : Colors.red,
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: alert['type'] == 'no_show'
                                                      ? Colors.orange.shade100
                                                      : Colors.red.shade100,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    alert['type'] == 'no_show'
                                                      ? '⚠️ NO-SHOW'
                                                      : '❌ MISSED',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: alert['type'] == 'no_show'
                                                        ? Colors.orange.shade700
                                                        : Colors.red.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              alert['message'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PASSENGER ISSUES DETECTED',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_passengerAlerts.length} ${_passengerAlerts.length == 1 ? 'Issue' : 'Issues'} - Tap to view',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Active Rides Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _activeRides.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: const Text(
                        'Trip and route data will appear here once active rides are detected from the backend.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Routes Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Routes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getRouteCount()} ${_getRouteCount() == 1 ? 'Route' : 'Routes'}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._buildRouteCards(),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Report Issue',
                          Icons.report_problem,
                          Colors.red,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Break',
                          Icons.coffee,
                          Colors.brown,
                          () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Fuel Stop',
                          Icons.local_gas_station,
                          Colors.orange,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Help',
                          Icons.help_outline,
                          Colors.blue,
                          () {},
                        ),
                      ),
                    ],
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child:InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(dynamic ride) {
    final rideId = ride['id'] ?? 0;
    final passengerId = ride['passenger_id'] ?? 0;
    final stationName = ride['station_name'] ?? 'Unknown Station';
    final status = ride['status'] ?? 'ongoing';
    final startedAt = ride['started_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Ride #$rideId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Destination: $stationName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Passenger ID: $passengerId',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (startedAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Started: ${_formatTime(startedAt)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int _getRouteCount() {
    // Count unique destination stations
    final stations = <String>{};
    for (var ride in _activeRides) {
      stations.add(ride['station_name'] ?? '');
    }
    return stations.length;
  }

  List<Widget> _buildRouteCards() {
    // Group rides by station (route)
    final Map<String, List<dynamic>> routeGroups = {};
    for (var ride in _activeRides) {
      final station = ride['station_name'] ?? 'Unknown';
      if (!routeGroups.containsKey(station)) {
        routeGroups[station] = [];
      }
      routeGroups[station]!.add(ride);
    }

    // Build a card for each route
    return routeGroups.entries.map((entry) {
      final stationName = entry.key;
      final passengers = entry.value;
      final passengerCount = passengers.length;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '$passengerCount ${passengerCount == 1 ? 'passenger' : 'passengers'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: passengers.map<Widget>((ride) {
                final passengerId = ride['passenger_id'] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'P$passengerId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }
}
