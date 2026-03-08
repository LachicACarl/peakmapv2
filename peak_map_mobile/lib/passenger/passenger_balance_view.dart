import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class PassengerBalanceView extends StatefulWidget {
  final String userId;
  final String userName;

  const PassengerBalanceView({
    Key? key,
    required this.userId,
    this.userName = 'Passenger',
  }) : super(key: key);

  @override
  State<PassengerBalanceView> createState() => _PassengerBalanceViewState();
}

class _PassengerBalanceViewState extends State<PassengerBalanceView> {
  static const double _minimumRideBalance = 50.0;
  static const double _defaultFarePhp = 15.0;

  double _balance = 0.0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  String? _errorMessage;
  int _selectedTab = 0; // 0 = Balance, 1 = History
  DateTime? _lastUpdatedAt;

  String? _linkedCardUid;
  String? _linkedCardAlias;
  String? _linkedCardStatus;

  String get _cardStorageKey => 'passenger_linked_card_uid_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _initializeCardState();
  }

  Future<void> _initializeCardState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCardUid = prefs.getString(_cardStorageKey);

    if (!mounted) return;
    setState(() {
      _linkedCardUid = savedCardUid;
    });

    await _loadBalanceAndTransactions();
  }

  int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value.trim());
  }

  bool _isCardOwnedByCurrentPassenger(String? ownerId) {
    final ownerInt = _parseInt(ownerId);
    final currentInt = _parseInt(widget.userId);

    if (ownerInt != null && currentInt != null) {
      return ownerInt == currentInt;
    }

    return (ownerId ?? '').trim() == widget.userId.trim();
  }

  Future<void> _loadBalanceAndTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cardUid = _linkedCardUid?.trim();
      if (cardUid == null || cardUid.isEmpty) {
        if (!mounted) return;
        setState(() {
          _balance = 0.0;
          _transactions = [];
          _linkedCardAlias = null;
          _linkedCardStatus = null;
          _lastUpdatedAt = DateTime.now();
          _isLoading = false;
        });
        return;
      }

      final cardPayload = await ApiService.getCardTapInfo(cardUid);
      if (cardPayload['success'] != true || cardPayload['registered'] != true) {
        final message = cardPayload['message']?.toString() ??
            'Card is not registered. Please link a valid card.';
        throw Exception(message);
      }

      final cardUser = (cardPayload['user'] as Map?)?.cast<String, dynamic>();
      final cardOwnerId = cardUser?['user_id']?.toString();

      if (cardOwnerId == null) {
        throw Exception('This card is not assigned to any passenger account.');
      }

      if (!_isCardOwnedByCurrentPassenger(cardOwnerId)) {
        throw Exception('This card belongs to another account. Link only your own card.');
      }

      final cardInfo = (cardPayload['card'] as Map?)?.cast<String, dynamic>();
      final balanceInfo = (cardPayload['balance'] as Map?)?.cast<String, dynamic>();

      final cardBalance = (balanceInfo?['amount'] as num?)?.toDouble() ?? 0.0;
      final ownerUserId = cardOwnerId;

      final transactionsResponse = await ApiService.getUserTransactions(ownerUserId);
      final rawTransactions = transactionsResponse['transactions'];
      final transactions = <Map<String, dynamic>>[];

      if (rawTransactions is List) {
        for (final item in rawTransactions) {
          if (item is Map) {
            transactions.add(item.cast<String, dynamic>());
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _balance = cardBalance;
        _transactions = transactions;
        _linkedCardAlias = cardInfo?['alias']?.toString();
        _linkedCardStatus = cardInfo?['status']?.toString();
        _lastUpdatedAt = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading card balance: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _promptLinkCard() async {
    final controller = TextEditingController(text: _linkedCardUid ?? '');

    final typedUid = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add My Card'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Card UID',
            hintText: 'e.g. 1603310630',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final value = controller.text.trim();
            Navigator.of(dialogContext).pop(value.isEmpty ? null : value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.of(dialogContext).pop(value.isEmpty ? null : value);
            },
            child: const Text('Link Card'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (typedUid == null) return;
    await _linkCard(typedUid);
  }

  Future<void> _linkCard(String cardUid) async {
    final normalized = cardUid.trim().toUpperCase();
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card UID is required.')),
      );
      return;
    }

    try {
      final payload = await ApiService.getCardTapInfo(normalized);
      if (payload['success'] != true || payload['registered'] != true) {
        final message = payload['message']?.toString() ?? 'Card is not registered.';
        throw Exception(message);
      }

      final user = (payload['user'] as Map?)?.cast<String, dynamic>();
      final ownerId = user?['user_id']?.toString();
      if (ownerId == null || !_isCardOwnedByCurrentPassenger(ownerId)) {
        throw Exception('This card is not assigned to your passenger account.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cardStorageKey, normalized);

      if (!mounted) return;
      setState(() {
        _linkedCardUid = normalized;
      });

      await _loadBalanceAndTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card $normalized linked successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to link card: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmRemoveCard() async {
    if (_linkedCardUid == null) return;

    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Linked Card'),
        content: const Text('This will unlink your current card from this app session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (remove != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cardStorageKey);

    if (!mounted) return;
    setState(() {
      _linkedCardUid = null;
      _linkedCardAlias = null;
      _linkedCardStatus = null;
      _balance = 0.0;
      _transactions = [];
      _errorMessage = null;
      _lastUpdatedAt = DateTime.now();
    });
  }

  Future<void> _promptTopUpAmount() async {
    if (_linkedCardUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link your card first before topping up.')),
      );
      return;
    }

    final controller = TextEditingController(text: '100');
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Top Up Card'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (PHP)',
            hintText: 'Enter amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.of(dialogContext).pop(parsed);
            },
            child: const Text('Top Up'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (amount == null) return;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Top-up amount must be greater than zero.')),
      );
      return;
    }

    await _topUpCard(amount);
  }

  Future<void> _topUpCard(double amount) async {
    try {
      final response = await ApiService.loadBalance(
        userId: widget.userId,
        amount: amount,
        paymentMethod: 'admin_nfc',
        cardId: _linkedCardUid,
      );

      if (response['success'] != true) {
        final message = response['message']?.toString() ?? 'Top-up failed.';
        throw Exception(message);
      }

      await _loadBalanceAndTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Top-up successful: ₱${amount.toStringAsFixed(2)} added.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Top-up failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Balance'),
        backgroundColor: const Color(0xFF355872),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadBalanceAndTransactions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Error loading balance',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadBalanceAndTransactions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF355872),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBalanceAndTransactions,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildPrimaryCard(),
                          const SizedBox(height: 12),
                          _buildCardLinkPanel(),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedTab = 0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 0
                                            ? const Color(0xFF7AAACE)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Balance Info',
                                          style: TextStyle(
                                            color: _selectedTab == 0
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedTab = 1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 1
                                            ? const Color(0xFF7AAACE)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'History',
                                          style: TextStyle(
                                            color: _selectedTab == 1
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedTab == 0)
                            _buildBalanceInfo()
                          else
                            _buildTransactionHistory(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildPrimaryCard() {
    final balanceValue = _balance.toStringAsFixed(2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF355872), Color(0xFF1a1f2e)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -16,
              child: Icon(
                Icons.contactless,
                size: 180,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formattedCardNumber(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _linkedCardUid == null
                        ? 'No linked card'
                        : 'Card UID: ${_linkedCardUid!}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _linkedCardAlias?.trim().isNotEmpty == true
                        ? _linkedCardAlias!
                        : 'beep Card',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Available balance as of\n${_formattedAsOf()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱$balanceValue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLinkPanel() {
    final hasLinkedCard = _linkedCardUid != null && _linkedCardUid!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E5EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF355872)),
              const SizedBox(width: 8),
              const Text(
                'My Card',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (hasLinkedCard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (_linkedCardStatus ?? 'active').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasLinkedCard
                ? 'Linked card UID: ${_linkedCardUid!}'
                : 'Link your own card first so you can check balance and top up.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _promptLinkCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF355872),
                  ),
                  icon: Icon(hasLinkedCard ? Icons.sync : Icons.add),
                  label: Text(hasLinkedCard ? 'Change Card' : 'Add My Card'),
                ),
              ),
              if (hasLinkedCard) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _confirmRemoveCard,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formattedCardNumber() {
    final source = _linkedCardUid?.trim() ?? '';
    if (source.isEmpty) return 'NO CARD LINKED';

    final digitsOnly = source.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 16) {
      return digitsOnly.substring(0, 16);
    }
    if (digitsOnly.isNotEmpty) {
      return digitsOnly.padRight(16, '0');
    }

    return source.toUpperCase();
  }

  String _formattedAsOf() {
    final timestamp = _lastUpdatedAt ?? DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final hour12 = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';

    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year} '
        '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  Widget _buildBalanceInfo() {
    if (_linkedCardUid == null || _linkedCardUid!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            const Icon(Icons.credit_card_off, size: 42, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'No linked card yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your card to check your card balance and top up.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _promptLinkCard,
              icon: const Icon(Icons.add_card),
              label: const Text('Add My Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355872),
              ),
            ),
          ],
        ),
      );
    }

    final currentBalance = _balance;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Balance Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.account_balance_wallet,
                      label: 'Current Balance',
                      value: '₱${currentBalance.toStringAsFixed(2)}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.directions_bus,
                      label: 'Fare Amount',
                      value: '₱${_defaultFarePhp.toStringAsFixed(2)}',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.confirmation_num,
                      label: 'Trips Available',
                      value: currentBalance > 0
                          ? '${(currentBalance / _defaultFarePhp).floor()}'
                          : '0',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.receipt_long,
                      label: 'Transactions',
                      value: '${_transactions.length}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (currentBalance < _minimumRideBalance)
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Balance Alert',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Balance is below ₱${_minimumRideBalance.toStringAsFixed(0)}. Top up your card before your next trip.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _promptTopUpAmount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 24),
            label: const Text(
              'Top Up Card',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    if (_linkedCardUid == null || _linkedCardUid!.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: const [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Link your card first to view transaction history.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _transactions.asMap().entries.map((entry) {
        final index = entry.key;
        final txn = entry.value;
        final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
        final method = txn['method']?.toString() ?? 'unknown';
        final createdAt = txn['created_at']?.toString() ?? 'N/A';
        final isLoad = method.contains('admin_nfc');

        return Container(
          margin: EdgeInsets.only(bottom: index < _transactions.length - 1 ? 12 : 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLoad
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLoad ? Icons.add_circle : Icons.remove_circle,
                    color: isLoad ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoad ? 'Balance Loaded' : 'Fare Deducted',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  isLoad ? '+₱${amount.toStringAsFixed(2)}' : '-₱${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLoad ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
