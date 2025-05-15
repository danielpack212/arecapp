import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Future<void> initializeLocalNotifications() async {
    // Initialize the Android settings for local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    // Initialize local notifications
    await flutterLocalNotificationsPlugin.initialize(settings);

    // Create a notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Must match your notification channel ID
      'High Importance Notifications',
      description: 'Used for important notifications',
      importance: Importance.high,
      playSound: true,        // Play sound
      enableLights: true,     // Enable lights
      enableVibration: true,  // Enable vibration
      // lightColor: Colors.blue, // REMOVE this line as this may raise an error if not defined
    );

    // Create the notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<AuthorizationStatus> requestNotificationPermissions() async {
    NotificationSettings settings = await messaging.requestPermission();
    return settings.authorizationStatus;
  }

  Future<String?> getFCMToken() async {
    return await messaging.getToken();
  }

  Future<bool> sendTokenToServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/send-token'), // Update as necessary for your server
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        print('✅ Token sent successfully');
        return true;
      } else {
        print('❌ Failed to send the token: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('🚨 HTTP error while sending token: $e');
      return false;
    }
  }

  /// Show a local notification from a RemoteMessage
  void showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Ensure this matches your channel ID
            'High Importance Notifications',
            channelDescription: 'Used for important notifications',
            importance: Importance.high,  // Important for heads-up notification
            priority: Priority.high,       // High priority for critical alerts
            playSound: true,               // Enable sound
            enableLights: true,            // Enable lights
            enableVibration: true,         // Enable vibration
            icon: '@mipmap/ic_launcher',   // The icon to show with the notification
          ),
        ),
      );
    }
  }
}