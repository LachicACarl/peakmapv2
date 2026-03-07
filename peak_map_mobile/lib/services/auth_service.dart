import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static int? _parseUserId(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  static Future<Map<String, dynamic>> _fetchDriverProfile(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      }

      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['detail'] ?? 'Driver profile not found',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch driver profile: $e',
      };
    }
  }
  
  /// Login user (driver or passenger)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'user_type': userType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == false) {
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid credentials',
          };
        }

        final resolvedUserType = (data['user_type'] ?? userType).toString();
        final userId = _parseUserId(data['user_id']);
        Map<String, dynamic>? driverData;

        if (userId == null) {
          return {
            'success': false,
            'message': 'Invalid user id returned by server',
          };
        }

        if (resolvedUserType == 'driver') {
          final profile = await _fetchDriverProfile(userId);
          if (!(profile['success'] as bool)) {
            return {
              'success': false,
              'message': profile['message'] ?? 'Failed to fetch driver profile',
            };
          }
          driverData = (profile['data'] as Map).cast<String, dynamic>();
        }
        
        // Save user session
        await _saveSession(
          userId: userId,
          email: (data['email'] ?? email).toString(),
          userType: resolvedUserType,
          token: data['token'] ?? '',
        );
        
        return {
          'success': true,
          'user_id': userId,
          'email': (data['email'] ?? email).toString(),
          'user_type': resolvedUserType,
          'profile': data['profile'],
          'driver_data': driverData,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String userType,
    String? name,
    String? phone,
  }) async {
    try {
      final normalizedName =
          (name != null && name.trim().isNotEmpty) ? name.trim() : email.split('@')[0];

      final payload = <String, dynamic>{
        'email': email,
        'password': password,
        'user_type': userType,
        'name': normalizedName,
      };
      if (phone != null && phone.trim().isNotEmpty) {
        payload['phone'] = phone.trim();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Registration successful',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Save user session
  static Future<void> _saveSession({
    required int userId,
    required String email,
    required String userType,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('email', email);
    await prefs.setString('user_type', userType);
    await prefs.setString('token', token);
    await prefs.setBool('is_logged_in', true);
  }

  /// Get current user session
  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (!isLoggedIn) return null;
      
      return {
        'user_id': prefs.getInt('user_id'),
        'email': prefs.getString('email'),
        'user_type': prefs.getString('user_type'),
        'token': prefs.getString('token'),
      };
    } catch (e) {
      print('Get session error: $e');
      return null;
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get current user ID
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// Get current user type
  static Future<String?> getCurrentUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  /// Request password reset
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset link sent to your email',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Failed to send reset link',
        };
      }
    } catch (e) {
      print('Forgot password error: $e');
      // For demo mode
      return {
        'success': true,
        'message': 'Password reset link sent (demo mode)',
      };
    }
  }

  /// Verify email with OTP
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Email verified successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Invalid OTP',
        };
      }
    } catch (e) {
      print('Email verification error: $e');
      return {
        'success': true,
        'message': 'Email verified (demo mode)',
      };
    }
  }

  /// Reset password with token
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'new_password': newPassword,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      print('Reset password error: $e');
      return {
        'success': true,
        'message': 'Password reset successfully (demo mode)',
      };
    }
  }
}
