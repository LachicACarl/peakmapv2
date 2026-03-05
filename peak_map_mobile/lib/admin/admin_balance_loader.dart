import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peak_map_mobile/services/nfc_service.dart';
import 'package:peak_map_mobile/services/api_service.dart';

class AdminBalanceLoader extends StatefulWidget {
  const AdminBalanceLoader({Key? key}) : super(key: key);

  @override
  State<AdminBalanceLoader> createState() => _AdminBalanceLoaderState();
}

class _AdminBalanceLoaderState extends State<AdminBalanceLoader> {
  final NFCService _nfcService = NFCService();
  
  bool _isNFCAvailable = false;
  bool _isReading = false;
  bool _isProcessing = false;
  
  String? _detectedCardId;
  String? _detectedUserId;
  double _balance = 0;
  double _loadAmount = 100;
  
  String? _statusMessage;
  Color? _statusColor;

  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
    _balanceController.text = _loadAmount.toString();
  }

  Future<void> _checkNFCAvailability() async {
    try {
      bool available = await _nfcService.isNFCAvailable();
      setState(() {
        _isNFCAvailable = available;
      });
      
      print('✅ NFC Available: $available');
    } catch (e) {
      print('❌ NFC check error: $e');
      setState(() {
        _isNFCAvailable = false;
      });
    }
  }

  Future<void> _scanCard() async {
    setState(() {
      _isReading = true;
      _statusMessage = 'Tap NFC card to scan...';
      _statusColor = Colors.blue;
      _detectedCardId = null;
      _detectedUserId = null;
    });

    try {
      NFCCardData? cardData = await _nfcService.readCard();
      
      if (cardData != null) {
        setState(() {
          _detectedCardId = cardData.cardId;
          _detectedUserId = cardData.userId;
          _userIdController.text = cardData.userId;
          _statusMessage = '✅ Card detected! User ID: ${cardData.userId}';
          _statusColor = Colors.green;
        });
        
        print('✅ Card scanned: ${cardData.userId}');
      } else {
        setState(() {
          _statusMessage = '⚠️ No card detected. Try again.';
          _statusColor = Colors.orange;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
        _statusColor = Colors.red;
      });
      print('❌ Scan error: $e');
    } finally {
      setState(() {
        _isReading = false;
      });
    }
  }

  Future<void> _loadBalance() async {
    if (_userIdController.text.isEmpty) {
      setState(() {
        _statusMessage = '❌ Please enter or scan a User ID';
        _statusColor = Colors.red;
      });
      return;
    }

    try {
      double amount = double.parse(_balanceController.text);
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Processing balance load...';
        _statusColor = Colors.blue;
      });

      // Call backend API to load balance
      final response = await ApiService.loadBalance(
        userId: _userIdController.text,
        amount: amount,
        paymentMethod: 'admin_nfc',
        cardId: _detectedCardId,
      );

      if (response['success'] == true) {
        setState(() {
          _statusMessage = '✅ Balance loaded successfully!';
          _statusColor = Colors.green;
          _balance += amount;
          
          // Reset form
          _userIdController.clear();
          _detectedCardId = null;
          _detectedUserId = null;
          _balanceController.text = _loadAmount.toString();
        });

        // Show success dialog
        _showSuccessDialog(amount);
      } else {
        setState(() {
          _statusMessage = '❌ Error: ${response['error'] ?? 'Unknown error'}';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
        _statusColor = Colors.red;
      });
      print('❌ Balance load error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Balance Loaded'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${_userIdController.text}'),
            const SizedBox(height: 8),
            Text('Amount: ₱${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Total Balance: ₱${_balance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Text(
              'Timestamp: ${DateTime.now().toString()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _userIdController.dispose();
    _nfcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin - Balance Loader (NFC)'),
        backgroundColor: const Color(0xFF355872),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NFC Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isNFCAvailable ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isNFCAvailable ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isNFCAvailable ? Icons.check_circle : Icons.error,
                      color: _isNFCAvailable ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isNFCAvailable ? 'NFC Ready' : 'NFC Unavailable',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isNFCAvailable
                                ? 'NFC is enabled and ready to use'
                                : 'This device does not support NFC',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Scan Card Button
              ElevatedButton.icon(
                onPressed: _isNFCAvailable && !_isReading ? _scanCard : null,
                icon: const Icon(Icons.contactless),
                label: Text(_isReading ? 'Scanning...' : 'Tap to Scan Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7AAACE),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Detected Card Info
              if (_detectedCardId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card Detected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Card ID: $_detectedCardId'),
                      Text('User ID: $_detectedUserId'),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // User ID Input
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Scan card or enter user ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Balance Input
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Load Amount (₱)',
                  hintText: 'Enter amount to load',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 20),

              // Quick amount buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [100, 200, 500, 1000].map((amount) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _balanceController.text = amount.toString();
                          });
                        },
                        child: Text('₱$amount'),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Status Message
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor ?? Colors.grey),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusColor ?? Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Load Balance Button
              ElevatedButton(
                onPressed: !_isProcessing && _isNFCAvailable ? _loadBalance : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF355872),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : 'Load Balance',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Statistics Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Loaded:'),
                        Text(
                          '₱${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF7AAACE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
