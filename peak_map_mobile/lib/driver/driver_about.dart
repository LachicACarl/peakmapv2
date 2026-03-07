import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverAbout extends StatefulWidget {
  final int driverId;
  final String email;
  
  const DriverAbout({
    Key? key, 
    required this.driverId,
    required this.email,
  }) : super(key: key);

  @override
  State<DriverAbout> createState() => _DriverAboutState();
}

class _DriverAboutState extends State<DriverAbout> {
  String driverName = 'Driver';
  String driverEmail = '';
  String phoneNumber = 'Not set';
  String licenseNumber = 'Not set';
  String plateNumber = 'Not set';
  String vehicleModel = 'Not set';

  Future<void> _loadDriverProfile() async {
    try {
      final profile = await ApiService.getDriverProfile(widget.driverId);
      if (!mounted) return;

      setState(() {
        driverName = (profile['full_name'] ?? driverName).toString();
        phoneNumber = (profile['phone_number'] ?? phoneNumber).toString();
      });
    } catch (_) {
      // Keep fallback values if driver profile endpoint is unavailable.
    }
  }

  @override
  void initState() {
    super.initState();
    driverEmail = widget.email;
    _loadDriverProfile();
  }

  void _showEditDialog(String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                onSave(controller.text);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF00BCD4),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Driver ID: ${widget.driverId}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
                // Account Information Section
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1f2e),
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildEditableInfoCard(Icons.person_outline, 'Full Name', driverName, () {
                  _showEditDialog('Full Name', driverName, (value) {
                    driverName = value;
                  });
                }),
                const SizedBox(height: 10),
                
                _buildEditableInfoCard(Icons.email_outlined, 'Email', driverEmail, () {
                  _showEditDialog('Email', driverEmail, (value) {
                    driverEmail = value;
                  });
                }),
                const SizedBox(height: 10),
                
                _buildEditableInfoCard(Icons.phone_outlined, 'Phone Number', phoneNumber, () {
                  _showEditDialog('Phone Number', phoneNumber, (value) {
                    phoneNumber = value;
                  });
                }),
                
                const SizedBox(height: 25),
                
                // Vehicle Information Section
                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1f2e),
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildEditableInfoCard(Icons.badge_outlined, 'License Number', licenseNumber, () {
                  _showEditDialog('License Number', licenseNumber, (value) {
                    licenseNumber = value;
                  });
                }),
                const SizedBox(height: 10),
                
                _buildEditableInfoCard(Icons.pin_outlined, 'Plate Number', plateNumber, () {
                  _showEditDialog('Plate Number', plateNumber, (value) {
                    plateNumber = value;
                  });
                }),
                const SizedBox(height: 10),
                
                _buildEditableInfoCard(Icons.directions_bus_outlined, 'Vehicle Model', vehicleModel, () {
                  _showEditDialog('Vehicle Model', vehicleModel, (value) {
                    vehicleModel = value;
                  });
                }),
                
                const SizedBox(height: 25),
                
                // Settings Section
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1f2e),
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildMenuCard(Icons.notifications_outlined, 'Notifications', 'Manage notification preferences', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications settings')),
                  );
                }),
                const SizedBox(height: 10),
                
                _buildMenuCard(Icons.lock_outline, 'Change Password', 'Update your password', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change password')),
                  );
                }),
                const SizedBox(height: 10),
                
                _buildMenuCard(Icons.help_outline, 'Help & Support', 'Get help and contact support', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support')),
                  );
                }),
                const SizedBox(height: 10),
                
                _buildMenuCard(Icons.privacy_tip_outlined, 'Privacy Policy', 'Read our privacy policy', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy')),
                  );
                }),
                
                const SizedBox(height: 25),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoCard(IconData icon, String label, String value, VoidCallback onEdit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1f2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00BCD4), size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Color(0xFF00BCD4), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00BCD4), size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1f2e),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
