import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // Initialize the local notifications plugin
    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onSelectNotification: (String? payload) async {
        // Handle notification tapped logic here, if necessary
        print("Notification tapped with payload: $payload");
      },
    );

    // Create the notification channel for Android 8.0+
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',  // Must match the channel ID used in showLocalNotification
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    // Check if the channel already exists on the device
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin(); // This should be the same instance as above
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<NotificationSettings> requestNotificationPermissions() async {
    NotificationSettings settings = await messaging.requestPermission();
    return settings;
  }

  Future<String?> getFCMToken() async {
    return await messaging.getToken();
  }

  Future<bool> sendTokenToServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse('http://YOUR_SERVER_ENDPOINT/send-token'), // Replace with your actual endpoint
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
            'high_importance_channel',  // Use the same ID as the channel created 
            'High Importance Notifications',
            channelDescription: 'Used for important notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',  // Set your app's launcher icon here
          ),
        ),
      );
    }
  }

  // This method should be called to handle background messages
  Future<void> onBackgroundMessage(RemoteMessage message) async {
    // Handle the background message here
    showLocalNotification(message);
  }

}