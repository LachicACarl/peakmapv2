import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Service for PEAK MAP Backend
/// 
/// Connects to local FastAPI backend on port 8000
class ApiService {
  // Backend URL - dynamically set based on environment
  static String get baseUrl {
    try {
      // For physical mobile device: use computer's local network IP
      return 'http://192.168.5.32:8000';
    } catch (e) {
      // Fallback for Android emulator
      return 'http://10.0.2.2:8000';
    }
  }
  
  /// Send GPS update from driver
  static Future<Map<String, dynamic>> updateGPS({
    required int driverId,
    required double latitude,
    required double longitude,
    required double speed,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/gps/update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "driver_id": driverId,
          "latitude": latitude,
          "longitude": longitude,
          "speed": speed,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to update GPS: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error updating GPS: $e");
    }
  }
  
  /// Get driver's latest GPS location
  static Future<Map<String, dynamic>> getLatestGPS(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/gps/latest/$driverId"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get GPS: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting GPS: $e");
    }
  }
  
  /// Get ETA from driver to station
  static Future<Map<String, dynamic>> getETA({
    required int driverId,
    required int stationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/eta/?driver_id=$driverId&station_id=$stationId"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get ETA: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting ETA: $e");
    }
  }
  
  /// Create a new ride session (Driver)
  static Future<Map<String, dynamic>> createSession(int driverId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/sessions/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"driver_id": driverId}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create session: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error creating session: $e");
    }
  }
  
  /// Join a ride session (Passenger scans driver QR)
  static Future<Map<String, dynamic>> joinSession({
    required String sessionCode,
    required int passengerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/sessions/join"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "session_code": sessionCode,
          "passenger_id": passengerId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to join session: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error joining session: $e");
    }
  }
  
  /// Confirm passenger and start ride (Driver scans passenger QR)
  static Future<Map<String, dynamic>> confirmPassenger({
    required int sessionId,
    required int passengerId,
    required int stationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/sessions/confirm"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "session_id": sessionId,
          "passenger_id": passengerId,
          "station_id": stationId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to confirm passenger: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error confirming passenger: $e");
    }
  }
  
  /// Check ride status (drop-off or missed detection)
  static Future<Map<String, dynamic>> checkRideStatus(int rideId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rides/check/$rideId"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to check ride status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error checking ride status: $e");
    }
  }
  
  /// Get all stations
  static Future<List<dynamic>> getStations() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/stations/"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get stations: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting stations: $e");
    }
  }

  /// Get card owner and current balance by card UID
  static Future<Map<String, dynamic>> getCardTapInfo(String cardUid) async {
    try {
      final encodedUid = Uri.encodeComponent(cardUid.trim());
      final response = await http.get(
        Uri.parse('$baseUrl/rfid/cards/tap/$encodedUid'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get card info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting card info: $e');
    }
  }
  
  /// Initiate payment for a ride
  static Future<Map<String, dynamic>> initiatePayment({
    required int rideId,
    required String method,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/initiate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ride_id": rideId,
          "method": method,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to initiate payment: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error initiating payment: $e");
    }
  }
  
  /// Confirm cash payment (Driver)
  static Future<Map<String, dynamic>> confirmCashPayment(int paymentId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/cash/confirm"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"payment_id": paymentId}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to confirm cash payment: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error confirming cash payment: $e");
    }
  }
  
  /// Get payment details
  static Future<Map<String, dynamic>> getPayment(int paymentId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payments/$paymentId"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get payment: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting payment: $e");
    }
  }
  
  /// Get payment by ride ID
  static Future<Map<String, dynamic>> getPaymentByRide(int rideId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payments/ride/$rideId"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get payment: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting payment: $e");
    }
  }
  
  /// Update driver online/offline status
  static Future<Map<String, dynamic>> updateDriverStatus({
    required int driverId,
    required bool isOnline,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/drivers/$driverId/status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"is_online": isOnline}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to update driver status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error updating driver status: $e");
    }
  }

  /// Get driver profile details
  static Future<Map<String, dynamic>> getDriverProfile(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/drivers/$driverId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get driver profile: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting driver profile: $e");
    }
  }
  
  /// Create a new ride (Passenger)
  static Future<Map<String, dynamic>> createRide({
    required int passengerId,
    required int stationId,
    int? driverId,
  }) async {
    try {
      final payload = <String, dynamic>{
        "passenger_id": passengerId,
        "station_id": stationId,
      };
      if (driverId != null) {
        payload["driver_id"] = driverId;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/rides"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create ride: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error creating ride: $e");
    }
  }

  /// Tap in passenger on bus entry via NFC/RFID card
  static Future<Map<String, dynamic>> tapInPassenger({
    required String userId,
    required String busId,
    required String driverId,
    required int stationId,
    String? cardUid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/tap-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'bus_id': busId,
          'driver_id': driverId,
          'station_id': stationId,
          'card_uid': cardUid,
        }),
      );

      final payload = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return payload;
      }

      if (payload is Map<String, dynamic>) {
        return {
          'success': false,
          ...payload,
        };
      }

      throw Exception('Failed to tap in: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error tapping in passenger: $e');
    }
  }
  
  /// Get driver's active rides
  static Future<List<dynamic>> getDriverRides(int driverId) async {
    return getDriverRidesByStatus(driverId: driverId, status: 'ongoing');
  }

  /// Get driver's rides filtered by status
  static Future<List<dynamic>> getDriverRidesByStatus({
    required int driverId,
    String? status,
  }) async {
    try {
      var url = "$baseUrl/rides?driver_id=$driverId";
      if (status != null && status.isNotEmpty) {
        url += "&status=$status";
      }

      final response = await http.get(
        Uri.parse(url),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get rides: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting rides: $e");
    }
  }
  
  /// Get rides for a passenger
  static Future<List<dynamic>> getPassengerRides(int passengerId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rides?passenger_id=$passengerId"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get rides: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting rides: $e");
    }
  }
  
  /// Get alerts for driver
  static Future<List<dynamic>> getDriverAlerts(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/alerts?driver_id=$driverId"),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        throw Exception("Failed to get alerts: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting alerts: $e");
    }
  }

  /// Get current passenger count for driver (from Supabase tap-in/tap-out)
  static Future<Map<String, dynamic>> getDriverPassengerCount(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/drivers/$driverId/passenger-count"),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get passenger count: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting passenger count: $e");
    }
  }

  /// Load balance to user account via NFC (Admin Only)
  static Future<Map<String, dynamic>> loadBalance({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? cardId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/load-balance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "amount": amount,
          "payment_method": paymentMethod,
          "card_id": cardId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Balance loaded: $amount to user $userId');
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load balance: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error loading balance: $e");
    }
  }

  /// Check user balance
  static Future<Map<String, dynamic>> checkBalance(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payments/balance/$userId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to check balance: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error checking balance: $e");
    }
  }

  /// Get user transaction history
  static Future<Map<String, dynamic>> getUserTransactions(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payments/transactions/$userId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get transactions: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting transactions: $e");
    }
  }

  /// Deduct fare from user balance (Bus Entry)
  static Future<Map<String, dynamic>> deductFare({
    required String userId,
    required double amount,
    required String busId,
    required String driverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/deduct-fare"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "amount": amount,
          "bus_id": busId,
          "driver_id": driverId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Fare deducted: ₱$amount from user $userId');
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['detail'] ?? 'Failed to deduct fare',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error deducting fare: $e',
      };
    }
  }

  /// Generic POST method for API calls
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Request failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error in POST request: $e");
    }
  }

  /// Get driver's daily sales report
  static Future<Map<String, dynamic>> getDriverDailySales(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payments/driver/$driverId/daily-sales"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get daily sales: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting daily sales: $e");
    }
  }

  /// Refund a transaction
  static Future<Map<String, dynamic>> refundTransaction({
    required int transactionId,
    String? reason,
    String? refundedBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/refund/$transactionId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "reason": reason,
          "refunded_by": refundedBy,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to refund transaction: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error refunding transaction: $e");
    }
  }

  /// Get card status
  static Future<Map<String, dynamic>> getCardStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payments/card/$userId/status"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get card status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error getting card status: $e");
    }
  }

  /// Block user's card
  static Future<Map<String, dynamic>> blockCard({
    required String userId,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/card/$userId/block"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "status": "blocked",
          "reason": reason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to block card: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error blocking card: $e");
    }
  }

  /// Request card replacement
  static Future<Map<String, dynamic>> requestCardReplacement({
    required String userId,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/card/$userId/replace"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "status": "pending_replacement",
          "reason": reason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to request replacement: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error requesting replacement: $e");
    }
  }
}
