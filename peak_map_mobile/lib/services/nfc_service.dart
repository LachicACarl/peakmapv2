import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  static final NFCService _instance = NFCService._internal();

  factory NFCService() {
    return _instance;
  }

  NFCService._internal();

  final StreamController<NFCCardData> _cardDataController =
      StreamController<NFCCardData>.broadcast();

  Stream<NFCCardData> get cardDataStream => _cardDataController.stream;

  /// Check if NFC is available on this device
  Future<bool> isNFCAvailable() async {
    try {
      if (kIsWeb) {
        return false;
      }
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      print('❌ NFC availability check error: $e');
      return false;
    }
  }

  /// Read NFC card for user/admin identification
  Future<NFCCardData?> readCard() async {
    try {
      bool isAvailable = await isNFCAvailable();
      if (!isAvailable) {
        throw Exception('NFC is not available on this device');
      }

      final completer = Completer<NFCCardData?>();

      try {
        await NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            print('✅ NFC Card detected!');
            print('Tag: ${tag.data}');

            final cardData = _parseTag(tag);
            _cardDataController.add(cardData);

            if (!completer.isCompleted) {
              completer.complete(cardData);
            }

            await NfcManager.instance.stopSession();
          },
        );
      } on PlatformException catch (e) {
        if (e.code == 'CANCELLED') {
          print('User cancelled NFC read');
          return null;
        }
        rethrow;
      }

      return completer.future;
    } catch (e) {
      print('❌ NFC read error: $e');
      rethrow;
    }
  }

  /// Start listening for NFC taps
  Stream<NFCCardData> startNFCListener() {
    _startListening();
    return _cardDataController.stream;
  }

  /// Stop NFC session
  Future<void> stopNFCSession() async {
    try {
      await NfcManager.instance.stopSession();
      print('✅ NFC session stopped');
    } catch (e) {
      print('❌ Error stopping NFC session: $e');
    }
  }

  /// Write balance data to NFC card (admin only)
  Future<bool> writeBalanceToCard({
    required String userId,
    required double balance,
  }) async {
    try {
      bool isAvailable = await isNFCAvailable();
      if (!isAvailable) {
        throw Exception('NFC is not available');
      }

      final completer = Completer<bool>();
      final balanceData = 'user:$userId|balance:$balance|timestamp:${DateTime.now().toIso8601String()}';

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
            await NfcManager.instance.stopSession();
            return;
          }

          try {
            final message = NdefMessage([
              NdefRecord.createText(balanceData),
            ]);

            await ndef.write(message);
            print('✅ Balance written to NFC card');
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          } catch (e) {
            print('❌ Error writing to NFC: $e');
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
      );

      return completer.future;
    } catch (e) {
      print('❌ NFC write error: $e');
      return false;
    }
  }

  void _startListening() async {
    try {
      bool isAvailable = await isNFCAvailable();
      if (!isAvailable) {
        throw Exception('NFC is not available');
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final cardData = _parseTag(tag);
          _cardDataController.add(cardData);
        },
      );
    } catch (e) {
      print('❌ NFC listener error: $e');
    }
  }

  NFCCardData _parseTag(NfcTag tag) {
    final ndef = Ndef.from(tag);
    String cardId = tag.data['nfca']?['identifier']?.toString() ?? 'unknown';
    String userId = cardId;

    if (ndef != null && ndef.cachedMessage != null) {
      for (var record in ndef.cachedMessage!.records) {
        try {
          final payload = String.fromCharCodes(record.payload);
          if (payload.contains('user:')) {
            userId = payload.split('user:').last.split('|').first.trim();
          } else if (payload.contains(':')) {
            userId = payload.split(':').last.trim();
          }
        } catch (e) {
          print('Error parsing record: $e');
        }
      }
    }

    return NFCCardData(
      cardId: cardId,
      userId: userId,
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    _cardDataController.close();
  }
}

/// Model for NFC Card Data
class NFCCardData {
  final String cardId;
  final String userId;
  final DateTime timestamp;

  NFCCardData({
    required this.cardId,
    required this.userId,
    required this.timestamp,
  });

  @override
  String toString() => 'NFCCardData(cardId: $cardId, userId: $userId, timestamp: $timestamp)';
}
