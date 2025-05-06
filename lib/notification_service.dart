import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Stream for foreground messages
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

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
        Uri.parse('http://10.0.2.2:3000/send-token'), // Replace with your real local IP
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

}
