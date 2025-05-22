import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Future<void> initializeLocalNotifications() async {
    if (kIsWeb) return; // Skip for web

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<AuthorizationStatus> requestNotificationPermissions() async {
    if (kIsWeb) return AuthorizationStatus.authorized; // Skip for web

    NotificationSettings settings = await messaging.requestPermission();
    return settings.authorizationStatus;
  }

  Future<String?> getFCMToken() async {
    if (kIsWeb) return null; // Skip for web
    return await messaging.getToken();
  }

  Future<bool> sendTokenToServer(String token) async {
    if (kIsWeb) return false; // Skip for web

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/send-token'),
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

  Future<void> saveTokenToFirestore(String token) async {
    if (kIsWeb) return; // Skip for web

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
      print('✅ FCM Token saved to Firestore');
    } catch (e) {
      print('🚨 Error saving FCM token to Firestore: $e');
    }
  }

  void showLocalNotification(RemoteMessage message) {
    if (kIsWeb) return; // Skip for web

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for important notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }


Future<bool> sendTaskAssignmentNotification(String technicianUid, String ticketId, String symptom) async {
  final serverUrl = kIsWeb
    ? 'http://localhost:3000/assign-task'  // Use your server's IP or domain for web
    : 'http://10.0.2.2:3000/assign-task';  // Use this for Android emulator
  print('Sending notification - Technician: $technicianUid, Task: $ticketId, Symptom: $symptom');

  try {
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'technicianUid': technicianUid,
        'ticketId': ticketId,
        'symptom': symptom,
      }),
    );
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Task assignment notification sent successfully');
      return true;
    } else {
      print('❌ Failed to send task assignment notification: ${response.statusCode}');
      print('Response body: ${response.body}');
      return false;
    }
  } catch (e) {
    print('🚨 Error while sending task assignment notification: $e');
    return false;
  }
}

  Stream<QuerySnapshot> getNotificationsForTechnician(String technicianUid) {
    return _firestore
        .collection('notifications')
        .where('technicianUid', isEqualTo: technicianUid)
        .where('read', isEqualTo: false)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }
}