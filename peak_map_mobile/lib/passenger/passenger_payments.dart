import 'package:flutter/material.dart';

class PassengerPayments extends StatelessWidget {
  final int passengerId;
  
  const PassengerPayments({Key? key, required this.passengerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final payments = [
      {
        'date': 'Feb 19, 2026',
        'route': 'Quezon Ave → Cubao',
        'amount': '₱40',
        'method': 'Cash',
        'status': 'Paid',
        'color': Colors.green,
      },
      {
        'date': 'Feb 18, 2026',
        'route': 'Ortigas → Shaw Blvd',
        'amount': '₱35',
        'method': 'QR Payment',
        'status': 'Paid',
        'color': Colors.green,
      },
      {
        'date': 'Feb 17, 2026',
        'route': 'Cubao → Guadalupe',
        'amount': '₱50',
        'method': 'Cash',
        'status': 'Paid',
        'color': Colors.green,
      },
      {
        'date': 'Feb 16, 2026',
        'route': 'Makati → Ayala',
        'amount': '₱30',
        'method': 'QR Payment',
        'status': 'Pending',
        'color': Colors.orange,
      },
      {
        'date': 'Feb 15, 2026',
        'route': 'Quezon Ave → Ortigas',
        'amount': '₱55',
        'method': 'Cash',
        'status': 'Paid',
        'color': Colors.green,
      },
    ];

    final totalPaid = payments
        .where((p) => p['status'] == 'Paid')
        .fold(0.0, (sum, p) => sum + double.parse((p['amount'] as String).replaceAll('₱', '')));

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
                      '💳 Payment History',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total Paid: ₱${totalPaid.toStringAsFixed(0)}',
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
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    payment['date'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (payment['color'] as Color).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      payment['status'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: payment['color'] as Color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.route,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      payment['route'] as String,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        payment['method'] == 'Cash'
                                            ? Icons.money
                                            : Icons.qr_code,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        payment['method'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    payment['amount'] as String,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
