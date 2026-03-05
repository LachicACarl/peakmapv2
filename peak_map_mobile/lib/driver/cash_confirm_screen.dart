import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CashConfirmScreen extends StatefulWidget {
  final int rideId;

  const CashConfirmScreen({
    Key? key,
    required this.rideId,
  }) : super(key: key);

  @override
  State<CashConfirmScreen> createState() => _CashConfirmScreenState();
}

class _CashConfirmScreenState extends State<CashConfirmScreen> {
  bool _isLoading = true;
  bool _isConfirming = false;
  Map<String, dynamic>? _payment;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    try {
      final payment = await ApiService.getPaymentByRide(widget.rideId);
      setState(() {
        _payment = payment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmCash() async {
    if (_payment == null) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final result = await ApiService.confirmCashPayment(_payment!['id']);
      
      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Cash Confirmed'),
            content: Text('Payment of ₱${_payment!['amount']} confirmed!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to map
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Cash Payment'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadPayment();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPaymentDetails(),
    );
  }

  Widget _buildPaymentDetails() {
    if (_payment == null) {
      return const Center(
        child: Text('No payment found for this ride'),
      );
    }

    final status = _payment!['status'];
    final amount = _payment!['amount'];
    final method = _payment!['method'];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment Info Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Amount:', '₱${amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  _buildDetailRow('Method:', method.toUpperCase()),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    'Status:',
                    status.toUpperCase(),
                    statusColor: status == 'paid'
                        ? Colors.green
                        : status == 'pending'
                            ? Colors.orange
                            : Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Status-based UI
          if (status == 'pending' && method == 'cash') ...[
            const Icon(
              Icons.money,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Collect ₱$amount from passenger',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isConfirming ? null : _confirmCash,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isConfirming
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'CONFIRM CASH RECEIVED',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ] else if (status == 'paid') ...[
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Confirmed ✅',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.info_outline,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              'Payment is $status',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
