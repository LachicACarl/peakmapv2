import 'package:flutter/material.dart';

class DriverAlerts extends StatelessWidget {
  final int driverId;
  
  const DriverAlerts({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        'title': 'New Passenger Request',
        'message': 'Passenger waiting at Quezon Avenue Station',
        'time': '5 min ago',
        'icon': Icons.person_add,
        'color': Colors.blue,
      },
      {
        'title': 'Traffic Alert',
        'message': 'Heavy traffic detected on EDSA Cubao',
        'time': '15 min ago',
        'icon': Icons.traffic,
        'color': Colors.orange,
      },
      {
        'title': 'Payment Received',
        'message': 'Cash payment confirmed - Ride #1234',
        'time': '30 min ago',
        'icon': Icons.payment,
        'color': Colors.green,
      },
      {
        'title': 'Maintenance Reminder',
        'message': 'Vehicle maintenance due in 3 days',
        'time': '2 hours ago',
        'icon': Icons.build,
        'color': Colors.red,
      },
      {
        'title': 'Route Update',
        'message': 'New route optimization available',
        'time': '3 hours ago',
        'icon': Icons.route,
        'color': Colors.purple,
      },
    ];

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
                      '${alerts.length} notifications',
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
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
                              color: (alert['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              alert['icon'] as IconData,
                              color: alert['color'] as Color,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            alert['title'] as String,
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
                                alert['message'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                alert['time'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
