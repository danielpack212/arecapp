import 'dart:html'; // For web notifications
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> initializeLocalNotifications() async {
    // Initialization not needed for web
  }

  Future<NotificationSettings> requestNotificationPermissions() async {
    NotificationSettings settings = await messaging.requestPermission();
    return settings;
  }

  Future<String?> getFCMToken() async {
    return await messaging.getToken();
  }

  void showLocalNotification(RemoteMessage message) {
    final notification = message.notification;

    if (notification != null) {
      _showWebNotification(notification);
    }
  }

  void _showWebNotification(RemoteNotification notification) {
    final title = notification.title ?? 'No Title';
    final body = notification.body ?? 'No Body';

    // Request notification permissions first
    Notification.requestPermission().then((permission) {
      if (permission == 'granted') {
        // Create and display a web notification
        Notification(title, body: body);
      }
    });
  }
}