import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http; // Import to use HTTP requests
import 'dart:convert'; // Import for JSON encoding

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> setupFCM() async {
    // Request permission for notifications
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission for notifications');
    } else {
      print('User declined permission for notifications');
    }

    // Get the FCM token
    String? token = await messaging.getToken();
    print("FCM Token: $token");

    // Send the token to your backend if it's not null
    if (token != null) {
      await sendTokenToServer(token); // Call the function to send the token
    }

    // Handle incoming messages when app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Received a message in the foreground: ${message.notification!.title}');
        // Optionally: Display a dialog or snackbar with message details
      }
    });
  }

  Future<void> sendTokenToServer(String token) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/send-token'), // Replace with your backend URL if needed
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': token,
      }),
    );

    if (response.statusCode == 200) {
      print('Token sent successfully');
    } else {
      print('Failed to send the token: ${response.statusCode}');
    }
  }
}