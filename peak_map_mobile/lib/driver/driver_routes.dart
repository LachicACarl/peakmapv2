import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverRoutes extends StatefulWidget {
  final int driverId;
  
  const DriverRoutes({Key? key, required this.driverId}) : super(key: key);

  @override
  State<DriverRoutes> createState() => _DriverRoutesState();
}

class _DriverRoutesState extends State<DriverRoutes> {
  String _selectedView = 'Active';
  bool _isLoadingRoutes = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _activeRoutes = [];
  List<Map<String, dynamic>> _completedRoutes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
      _errorMessage = null;
    });

    try {
      final activeRides = await ApiService.getDriverRidesByStatus(
        driverId: widget.driverId,
        status: 'ongoing',
      );

      final completedChunks = await Future.wait([
        ApiService.getDriverRidesByStatus(driverId: widget.driverId, status: 'completed'),
        ApiService.getDriverRidesByStatus(driverId: widget.driverId, status: 'dropped'),
        ApiService.getDriverRidesByStatus(driverId: widget.driverId, status: 'missed'),
        ApiService.getDriverRidesByStatus(driverId: widget.driverId, status: 'cancelled'),
      ]);

      final completedRides = completedChunks.expand((chunk) => chunk).toList();

      if (!mounted) return;
      setState(() {
        _activeRoutes = _normalizeRides(activeRides);
        _completedRoutes = _normalizeRides(completedRides);
        _isLoadingRoutes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load driver routes: $e';
        _isLoadingRoutes = false;
      });
    }
  }

  List<Map<String, dynamic>> _normalizeRides(List<dynamic> rides) {
    final normalized = rides
        .whereType<Map>()
        .map((ride) {
          final data = ride.cast<String, dynamic>();
          final status = (data['status'] ?? 'unknown').toString();
          return {
            'id': data['id'] ?? 0,
            'station_name': (data['station_name'] ?? 'Unknown station').toString(),
            'status': status,
            'status_color': _statusColor(status),
            'started_at': _formatTimestamp(data['started_at']),
            'ended_at': _formatTimestamp(data['ended_at']),
          };
        })
        .toList();

    normalized.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    return normalized;
  }

  String _formatTimestamp(dynamic rawValue) {
    if (rawValue == null) {
      return '--';
    }

    final value = rawValue.toString();
    try {
      final parsed = DateTime.parse(value).toLocal();
      final month = parsed.month.toString().padLeft(2, '0');
      final day = parsed.day.toString().padLeft(2, '0');
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    } catch (_) {
      return value;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ongoing':
        return Colors.blue;
      case 'completed':
      case 'dropped':
        return Colors.green;
      case 'missed':
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Routes & Trips',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your daily routes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // View Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildViewSelector('Active', Icons.directions_bus),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildViewSelector('Completed', Icons.check_circle),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Routes List
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingRoutes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRoutes,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return _selectedView == 'Active'
        ? _buildRoutesList(_activeRoutes)
        : _buildRoutesList(_completedRoutes);
  }

  Widget _buildViewSelector(String label, IconData icon) {
    final isSelected = _selectedView == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesList(List<Map<String, dynamic>> routes) {
    if (routes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return _buildRouteCard(route);
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show route details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride #${route['id']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            route['station_name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (route['status_color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        route['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: route['status_color'] as Color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Route Path
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Started',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            route['started_at'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ended',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            route['ended_at'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedView == 'Active' ? 'No active routes' : 'No completed routes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ride data will appear once trips are recorded in the backend.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
