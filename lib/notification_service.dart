import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _uuid = Uuid();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  Future<void> initializeLocalNotifications() async {
    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    }
  }

  Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) {
      return true;
    } else {
      // For Android, permissions are granted by default
      // For iOS, you'd need to request permissions here
      return true;
    }
  }

  Future<String?> getDeviceToken() async {
    return _uuid.v4();
  }

  Future<bool> sendTokenToServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse(kIsWeb ? 'http://localhost:3000/register-token' : 'http://10.0.2.2:3000/register-token'),
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

  void showLocalNotification(String title, String body) {
    if (kIsWeb) {
      print('Web Notification: $title - $body');
    } else {
      flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  Future<void> sendNotificationToUser(String userId, String title, String body, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(kIsWeb ? 'http://localhost:3000/send-notification' : 'http://10.0.2.2:3000/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'body': body,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        emitNotification(title, body);
      } else {
        print('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  void emitNotification(String title, String body) {
    _notificationController.add({
      'title': title,
      'body': body,
    });
  }

  void dispose() {
    _notificationController.close();
  }
}