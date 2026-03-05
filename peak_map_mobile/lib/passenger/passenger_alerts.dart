import 'package:flutter/material.dart';

class PassengerAlerts extends StatelessWidget {
  final int passengerId;
  
  const PassengerAlerts({Key? key, required this.passengerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        'title': 'Bus Arriving Soon',
        'message': 'Your bus is 2 minutes away from Quezon Avenue Station',
        'time': '1 min ago',
        'icon': Icons.directions_bus,
        'color': Colors.blue,
      },
      {
        'title': 'Payment Reminder',
        'message': 'Complete pending payment for Ride #4567',
        'time': '10 min ago',
        'icon': Icons.payment,
        'color': Colors.orange,
      },
      {
        'title': 'Route Detour',
        'message': 'Your bus route has been updated due to road closure',
        'time': '25 min ago',
        'icon': Icons.warning,
        'color': Colors.red,
      },
      {
        'title': 'Station Alert',
        'message': 'Cubao Station temporarily closed for maintenance',
        'time': '1 hour ago',
        'icon': Icons.info,
        'color': Colors.purple,
      },
      {
        'title': 'Special Promo',
        'message': '20% discount on rides this weekend!',
        'time': '2 hours ago',
        'icon': Icons.local_offer,
        'color': Colors.green,
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
