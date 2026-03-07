import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverAlerts extends StatefulWidget {
  final int driverId;
  
  const DriverAlerts({Key? key, required this.driverId}) : super(key: key);

  @override
  State<DriverAlerts> createState() => _DriverAlertsState();
}

class _DriverAlertsState extends State<DriverAlerts> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final alerts = await ApiService.getDriverAlerts(widget.driverId);
      if (!mounted) return;

      setState(() {
        _alerts = alerts
            .whereType<Map>()
            .map((raw) => raw.cast<String, dynamic>())
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load alerts: $e';
        _isLoading = false;
      });
    }
  }

  IconData _iconForAlert(Map<String, dynamic> alert) {
    final type = (alert['type'] ?? '').toString();
    if (type == 'payment_pending') {
      return Icons.payment;
    }
    if (type == 'ride_status') {
      return Icons.directions_bus;
    }
    return Icons.notifications;
  }

  Color _colorForAlert(Map<String, dynamic> alert) {
    final severity = (alert['severity'] ?? '').toString();
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.teal;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7AAACE), Color(0xFF355872)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔔 Alerts',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_alerts.length} notifications',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAlerts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return const Center(
        child: Text(
          'No alerts found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        final color = _colorForAlert(alert);
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForAlert(alert),
                color: color,
                size: 28,
              ),
            ),
            title: Text(
              (alert['title'] ?? 'Alert').toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  (alert['message'] ?? 'No details').toString(),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(alert['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
