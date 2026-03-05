import 'package:flutter/material.dart';

class PassengerSearchAlerts extends StatefulWidget {
  final int passengerId;
  
  const PassengerSearchAlerts({Key? key, required this.passengerId}) : super(key: key);

  @override
  State<PassengerSearchAlerts> createState() => _PassengerSearchAlertsState();
}

class _PassengerSearchAlertsState extends State<PassengerSearchAlerts> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _alerts = [
    {
      'title': 'Bus Arriving Soon',
      'message': 'Your bus to Cubao will arrive in 5 minutes',
      'time': '2 min ago',
      'type': 'arrival',
      'icon': Icons.directions_bus,
      'color': Colors.green,
      'isRead': false,
    },
    {
      'title': 'Trip Completed',
      'message': 'Your trip from Quezon Ave to Ortigas has been completed. Fare: ₱45',
      'time': '1 hour ago',
      'type': 'completed',
      'icon': Icons.check_circle,
      'color': Colors.blue,
      'isRead': false,
    },
    {
      'title': 'Payment Successful',
      'message': 'Your payment of ₱45.00 has been processed successfully',
      'time': '1 hour ago',
      'type': 'payment',
      'icon': Icons.payment,
      'color': Colors.green,
      'isRead': true,
    },
    {
      'title': 'Route Delay',
      'message': 'Your bus is experiencing a 10-minute delay due to traffic',
      'time': '3 hours ago',
      'type': 'delay',
      'icon': Icons.warning,
      'color': Colors.orange,
      'isRead': true,
    },
    {
      'title': 'New Route Available',
      'message': 'A new express route to Makati is now available!',
      'time': '1 day ago',
      'type': 'info',
      'icon': Icons.info,
      'color': Colors.cyan,
      'isRead': true,
    },
    {
      'title': 'Fare Update',
      'message': 'Fare rates have been updated. Check the new rates.',
      'time': '2 days ago',
      'type': 'update',
      'icon': Icons.update,
      'color': Colors.purple,
      'isRead': true,
    },
  ];

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
                    'Notifications & Alerts',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getFilteredAlerts().length} notification${_getFilteredAlerts().length != 1 ? 's' : ''}'
                    '${_selectedFilter != 'All' ? ' (${_selectedFilter})' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notifications...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Arrival'),
                  _buildFilterChip('Payment'),
                  _buildFilterChip('Delay'),
                  _buildFilterChip('Info'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Alerts List
            Expanded(
              child: _getFilteredAlerts().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _getFilteredAlerts().length,
                      itemBuilder: (context, index) {
                        final alert = _getFilteredAlerts()[index];
                        return _buildAlertCard(alert);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
          print('✅ Filter changed to: $label');
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.cyan,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredAlerts() {
    var filtered = _alerts.where((alert) {
      // Filter by selected category
      if (_selectedFilter != 'All') {
        final alertType = alert['type'].toString();
        final filterType = _selectedFilter.toLowerCase();
        
        // Map filter names to alert types
        final typeMapping = {
          'arrival': 'arrival',
          'payment': 'payment',
          'delay': 'delay',
          'info': ['info', 'update'],
        };
        
        if (filterType == 'arrival' && alert['type'] != 'arrival') return false;
        if (filterType == 'payment' && alert['type'] != 'payment') return false;
        if (filterType == 'delay' && alert['type'] != 'delay') return false;
        if (filterType == 'info' && alert['type'] != 'info' && alert['type'] != 'update') return false;
      }
      
      // Filter by search text
      if (_searchController.text.isNotEmpty) {
        final searchText = _searchController.text.toLowerCase();
        final title = alert['title'].toString().toLowerCase();
        final message = alert['message'].toString().toLowerCase();
        return title.contains(searchText) || message.contains(searchText);
      }
      
      return true;
    }).toList();
    
    return filtered;
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: alert['isRead'] ? Colors.white : Colors.cyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert['isRead'] ? Colors.grey[200]! : Colors.cyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              alert['isRead'] = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alert['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alert['icon'],
                    color: alert['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: alert['isRead']
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!alert['isRead'])
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.cyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alert['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
