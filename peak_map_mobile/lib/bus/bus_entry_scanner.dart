import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';

class BusEntryScanner extends StatefulWidget {
  final double baseFare;
  final String busId;
  final String driverId;

  const BusEntryScanner({
    Key? key,
    this.baseFare = 15.0, // Default ₱15 base fare
    required this.busId,
    required this.driverId,
  }) : super(key: key);

  @override
  State<BusEntryScanner> createState() => _BusScannerState();
}

class _BusScannerState extends State<BusEntryScanner> {
  late NFCService nfcService;
  String? scannedUserId;
  Map<String, dynamic>? cardData;
  bool nfcAvailable = false;
  bool isProcessing = false;
  String statusMessage = '';
  Color statusColor = Colors.grey;
  bool entryGranted = false;
  double? userBalance;
  double? newBalance;
  String? transactionId;
  int passengersBoarded = 0;

  @override
  void initState() {
    super.initState();
    nfcService = NFCService();
    _initializeNFC();
  }

  void _initializeNFC() async {
    try {
      bool available = await nfcService.isNFCAvailable();
      if (mounted) {
        setState(() {
          nfcAvailable = available;
          statusMessage = available ? '✅ NFC Ready - Scan card' : '❌ NFC Not Available';
          statusColor = available ? Colors.green : Colors.red;
        });
      }

      if (available) {
        _startListening();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusMessage = '⚠️ Error: ${e.toString()}';
          statusColor = Colors.red;
        });
      }
    }
  }

  void _startListening() {
    nfcService.startNFCListener().listen(
      (cardData) async {
        if (mounted) {
          await _processCard(cardData);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            statusMessage = '❌ NFC Error: $error';
            statusColor = Colors.red;
          });
        }
      },
    );
  }

  Future<void> _processCard(NFCCardData scannedData) async {
    setState(() {
      isProcessing = true;
      entryGranted = false;
      statusMessage = '⏳ Processing card...';
      statusColor = Colors.orange;
    });

    try {
      // Extract data from card
      final userId = scannedData.userId;
      final cardBalance = 0.0;

      if (userId == null || userId.isEmpty) {
        setState(() {
          statusMessage = '❌ Invalid card - No user ID';
          statusColor = Colors.red;
        });
        return;
      }

      setState(() {
        scannedUserId = userId;
        userBalance = cardBalance;
      });

      // Get current balance from backend
      final balanceResponse = await ApiService.checkBalance(userId);
      final backendBalance = balanceResponse['balance'] as double? ?? cardBalance;

      // Calculate new balance after fare
      final fareAmount = widget.baseFare;
      final calculateNewBalance = backendBalance - fareAmount;

      // Check if user has sufficient balance
      if (backendBalance < fareAmount) {
        setState(() {
          statusMessage =
              '❌ Insufficient Balance\nNeeded: ₱${fareAmount.toStringAsFixed(2)}\nAvailable: ₱${backendBalance.toStringAsFixed(2)}';
          statusColor = Colors.red;
          entryGranted = false;
          isProcessing = false;
        });
        _resetAfterDelay(3);
        return;
      }

      // Process payment (deduct fare)
      final paymentResponse = await ApiService.deductFare(
        userId: userId,
        amount: fareAmount,
        busId: widget.busId,
        driverId: widget.driverId,
      );

      if (paymentResponse['success'] == true) {
        // Update NFC card with new balance
        await nfcService.writeBalanceToCard(
          userId: userId,
          balance: calculateNewBalance,
        );

        setState(() {
          newBalance = calculateNewBalance;
          transactionId = paymentResponse['transaction_id'] as String?;
          entryGranted = true;
          statusMessage =
              '✅ Entry Granted\n💳 Fare: ₱${fareAmount.toStringAsFixed(2)}\n💰 New Balance: ₱${calculateNewBalance.toStringAsFixed(2)}';
          statusColor = Colors.green;
          passengersBoarded++;
        });

        _resetAfterDelay(4);
      } else {
        setState(() {
          statusMessage = '❌ Payment failed\n${paymentResponse['error'] ?? 'Unknown error'}';
          statusColor = Colors.red;
        });
        _resetAfterDelay(3);
      }
    } catch (e) {
      setState(() {
        statusMessage = '❌ Error: ${e.toString()}';
        statusColor = Colors.red;
      });
      _resetAfterDelay(3);
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _resetAfterDelay(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          scannedUserId = null;
          cardData = null;
          statusMessage = '✅ NFC Ready - Scan card';
          statusColor = Colors.green;
          entryGranted = false;
          userBalance = null;
          newBalance = null;
          transactionId = null;
        });
      }
    });
  }

  void _manualEntry() {
    showDialog(
      context: context,
      builder: (context) => _ManualEntryDialog(
        baseFare: widget.baseFare,
        busId: widget.busId,
        driverId: widget.driverId,
        onSuccess: (userId, goodbye) {
          setState(() {
            scannedUserId = userId;
            entryGranted = true;
            statusMessage = '✅ Manual Entry Granted\nUser: $userId';
            statusColor = Colors.green;
            passengersBoarded++;
          });
          _resetAfterDelay(3);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Entry Scanner'),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NFC Status Indicator
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  border: Border.all(color: statusColor, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(
                      entryGranted
                          ? Icons.check_circle_outline
                          : isProcessing
                              ? Icons.sync
                              : Icons.nfc,
                      size: 80,
                      color: statusColor,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (entryGranted) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '📱 User ID: $scannedUserId',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (userBalance != null)
                              Text(
                                '💾 Card Balance: ₱${userBalance!.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            if (newBalance != null)
                              Text(
                                '💰 New Balance: ₱${newBalance!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            if (transactionId != null)
                              Text(
                                'TXN: $transactionId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Bus Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text('🚌 Bus ID: ${widget.busId}'),
                      Text('👤 Driver ID: ${widget.driverId}'),
                      Text('💳 Base Fare: ₱${widget.baseFare.toStringAsFixed(2)}'),
                      Text('👥 Passengers Boarded: $passengersBoarded'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: nfcAvailable && !isProcessing ? _initializeNFC : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry NFC'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !isProcessing ? _manualEntry : null,
                      icon: const Icon(Icons.edit),
                      label: const Text('Manual Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transaction History
              if (transactionId != null)
                Card(
                  color: Colors.green.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ Transaction Successful',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Transaction ID: $transactionId'),
                        Text('Amount Deducted: ₱${widget.baseFare.toStringAsFixed(2)}'),
                      ],
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

class _ManualEntryDialog extends StatefulWidget {
  final double baseFare;
  final String busId;
  final String driverId;
  final Function(String userId, String? transactionId) onSuccess;

  const _ManualEntryDialog({
    required this.baseFare,
    required this.busId,
    required this.driverId,
    required this.onSuccess,
  });

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final userIdController = TextEditingController();
  bool isProcessing = false;
  String errorMessage = '';

  Future<void> _processManualEntry() async {
    final userId = userIdController.text.trim();
    if (userId.isEmpty) {
      setState(() {
        errorMessage = 'Please enter user ID';
      });
      return;
    }

    setState(() {
      isProcessing = true;
      errorMessage = '';
    });

    try {
      // Check balance
      final balanceResponse = await ApiService.checkBalance(userId);
      final balance = balanceResponse['balance'] as double? ?? 0.0;

      if (balance < widget.baseFare) {
        setState(() {
          errorMessage =
              'Insufficient balance: ₱${balance.toStringAsFixed(2)} (Need ₱${widget.baseFare.toStringAsFixed(2)})';
          isProcessing = false;
        });
        return;
      }

      // Deduct fare
      final paymentResponse = await ApiService.deductFare(
        userId: userId,
        amount: widget.baseFare,
        busId: widget.busId,
        driverId: widget.driverId,
      );

      if (paymentResponse['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess(
            userId,
            paymentResponse['transaction_id'] as String?,
          );
        }
      } else {
        setState(() {
          errorMessage = 'Payment failed: ${paymentResponse['error'] ?? 'Unknown error'}';
          isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: userIdController,
            decoration: InputDecoration(
              labelText: 'User ID (UUID)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: errorMessage.isEmpty ? null : errorMessage,
            ),
            enabled: !isProcessing,
          ),
          if (isProcessing) ...[
            const SizedBox(height: 15),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isProcessing ? null : _processManualEntry,
          child: isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Process'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    userIdController.dispose();
    super.dispose();
  }
}
