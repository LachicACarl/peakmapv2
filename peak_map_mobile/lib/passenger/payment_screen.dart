import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final int rideId;
  final double fareAmount;

  const PaymentScreen({
    Key? key,
    required this.rideId,
    required this.fareAmount,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  bool _isProcessing = false;
  String? _paymentStatus;

  Future<void> _initiatePayment(String method) async {
    setState(() {
      _isProcessing = true;
      _paymentStatus = null;
    });

    try {
      final result = await ApiService.initiatePayment(
        rideId: widget.rideId,
        method: method,
      );

      setState(() {
        _isProcessing = false;
        _selectedMethod = method;
      });

      if (method == 'cash') {
        // Cash payment - wait for driver confirmation
        _showCashWaitingDialog();
      } else if (method == 'gcash' || method == 'ewallet') {
        // E-wallet payment - show success
        _showEWalletSuccess(result);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _paymentStatus = 'Error: $e';
      });
      _showErrorDialog(e.toString());
    }
  }

  void _showCashWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('💵 Cash Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Waiting for driver to confirm...\n\nPlease hand ₱${widget.fareAmount.toStringAsFixed(2)} to the driver.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to map
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEWalletSuccess(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Payment Initiated'),
        content: Text(
          'Payment ID: ${result['payment_id']}\n\n'
          'In production, you would be redirected to the payment gateway.\n\n'
          'Mock checkout URL:\n${result['checkout_url'] ?? 'N/A'}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to map
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Payment Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fare Amount Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Total Fare',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₱${widget.fareAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Payment Method Title
            const Text(
              'Choose Payment Method:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Cash Button
            _buildPaymentButton(
              icon: Icons.money,
              label: 'Cash',
              method: 'cash',
              color: Colors.green,
            ),
            const SizedBox(height: 15),
            
            // GCash Button
            _buildPaymentButton(
              icon: Icons.account_balance_wallet,
              label: 'GCash',
              method: 'gcash',
              color: Colors.blue,
            ),
            const SizedBox(height: 15),
            
            // E-Wallet Button
            _buildPaymentButton(
              icon: Icons.credit_card,
              label: 'Other E-Wallet',
              method: 'ewallet',
              color: Colors.purple,
            ),
            
            if (_paymentStatus != null) ...[
              const SizedBox(height: 20),
              Text(
                _paymentStatus!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required String method,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : () => _initiatePayment(method),
      icon: Icon(icon, size: 30),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
