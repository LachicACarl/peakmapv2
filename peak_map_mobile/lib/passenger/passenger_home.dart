import 'package:flutter/material.dart';
import 'passenger_dashboard.dart';
import 'passenger_search_alerts.dart';
import 'passenger_about.dart';

class PassengerHome extends StatefulWidget {
  final int passengerId;
  final String email;
  final String? passengerName;
  final String? passengerPhone;
  
  const PassengerHome({
    Key? key,
    required this.passengerId,
    required this.email,
    this.passengerName,
    this.passengerPhone,
  }) : super(key: key);

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      PassengerDashboard(passengerId: widget.passengerId),
      PassengerSearchAlerts(passengerId: widget.passengerId),
      PassengerAbout(
        passengerId: widget.passengerId,
        email: widget.email,
        passengerName: widget.passengerName,
        passengerPhone: widget.passengerPhone,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f2e),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: const Color(0xFF1a1f2e),
            selectedItemColor: Colors.cyan,
            unselectedItemColor: Colors.grey[600],
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 28),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded, size: 28),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_rounded, size: 28),
                label: 'Menu',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
