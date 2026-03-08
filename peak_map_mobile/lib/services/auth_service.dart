import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      final scheme = Uri.base.scheme == 'https' ? 'https' : 'http';
      return '$scheme://$host:8000';
    }
    return 'http://192.168.5.32:8000';
  }

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
    // ALWAYS use backend API for authentication (both passenger and driver)
    // Backend handles Supabase auth + local fallback + rate limiting
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'user_type': userType,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == false) {
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid credentials',
          };
        }

        // Save session
        await _saveSession(
          userId: data['user_id'] is String 
            ? data['user_id'].hashCode 
            : (data['user_id'] as int? ?? 0),
          email: data['email'] ?? email,
          userType: userType,
          token: data['token'] ?? '',
        );

        return {
          'success': true,
          'user_id': data['user_id'],
          'supabase_user_id': data['supabase_user_id'],
          'email': data['email'],
          'user_type': data['user_type'] ?? userType,
          'token': data['token'],
          'profile': data['profile'],
          'auth_method': data['auth_method'] ?? 'backend',
        };
      }

      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['detail'] ?? 'Authentication failed',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please check your network.',
      };
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
    // ALWAYS use backend API for registration (both passenger and driver)
    // Backend handles Supabase registration + local fallback + rate limiting
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful! Please login.',
          'auth_method': data['auth_method'] ?? 'backend',
        };
      } else {
        String message = 'Registration failed (${response.statusCode})';
        try {
          final error = jsonDecode(response.body);
          if (error is Map) {
            message = (error['detail'] ?? error['message'] ?? message).toString();
          }
        } catch (_) {
          if (response.body.trim().isNotEmpty) {
            message = response.body;
          }
        }
        return {
          'success': false,
          'message': message,
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please check your network.',
      };
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check backend and try again.',
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
