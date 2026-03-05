import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Firebase Cloud Messaging Service
/// 
/// Handles:
/// - Push notification setup
/// - Topic subscriptions
/// - Foreground/background notifications
/// - Notification click handling
class NotificationService {
  static FirebaseMessaging? _messaging;
  static bool _isFirebaseAvailable = false;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  /// Initialize Firebase Messaging and Local Notifications
  static Future<void> initialize() async {
    try {
      // Check if Firebase is available
      _messaging = FirebaseMessaging.instance;
      _isFirebaseAvailable = true;
      
      // Request permission for iOS
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional permission');
      } else {
        print('❌ User declined notification permission');
      }

      // Initialize local notifications (for Android foreground)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          if (response.payload != null) {
            _notificationStreamController.add({'payload': response.payload});
          }
        },
      );

      // Get FCM token
      String? token = await _messaging!.getToken();
      print('📱 FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Foreground message received: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 Notification clicked: ${message.data}');
        _notificationStreamController.add({'data': message.data});
      });
    } catch (e) {
      print('⚠️ Firebase Messaging not available: $e');
      _isFirebaseAvailable = false;
    }
  }

  /// Show local notification when app is in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'peak_map_channel',
      'PEAK MAP Notifications',
      channelDescription: 'Ride updates and alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'PEAK MAP',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Subscribe to driver-specific notifications
  static Future<void> subscribeToDriver(int driverId) async {
    if (!_isFirebaseAvailable || _messaging == null) return;
    await _messaging!.subscribeToTopic('driver_$driverId');
    print('✅ Subscribed to driver_$driverId');
  }

  /// Subscribe to ride-specific notifications
  static Future<void> subscribeToRide(int rideId) async {
    if (!_isFirebaseAvailable || _messaging == null) return;
    await _messaging!.subscribeToTopic('ride_$rideId');
    print('✅ Subscribed to ride_$rideId');
  }

  /// Subscribe to passenger-specific notifications
  static Future<void> subscribeToPassenger(int passengerId) async {
    if (!_isFirebaseAvailable || _messaging == null) return;
    await _messaging!.subscribeToTopic('passenger_$passengerId');
    print('✅ Subscribed to passenger_$passengerId');
  }

  /// Unsubscribe from topics
  static Future<void> unsubscribeFromDriver(int driverId) async {
    if (!_isFirebaseAvailable || _messaging == null) return;
    await _messaging!.unsubscribeFromTopic('driver_$driverId');
    print('❌ Unsubscribed from driver_$driverId');
  }

  static Future<void> unsubscribeFromRide(int rideId) async {
    if (!_isFirebaseAvailable || _messaging == null) return;
    await _messaging!.unsubscribeFromTopic('ride_$rideId');
    print('❌ Unsubscribed from ride_$rideId');
  }

  static Future<void> unsubscribeFromPassenger(int passengerId) async {
    if (!_isFirebaseAvailable || _messaging == null) return;
    await _messaging!.unsubscribeFromTopic('passenger_$passengerId');
    print('❌ Unsubscribed from passenger_$passengerId');
  }

  /// Get FCM token for device-specific notifications
  static Future<String?> getToken() async {
    if (!_isFirebaseAvailable || _messaging == null) return null;
    return await _messaging!.getToken();
  }

  /// Show a simple snackbar notification
  static void showSnackbar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dispose resources
  static void dispose() {
    _notificationStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message: ${message.notification?.title}');
  // Handle background notification here if needed
}
