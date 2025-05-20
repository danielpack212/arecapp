import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'maintenance_log_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'notification_service.dart';
import 'landing_page.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'chat_provider.dart'; 


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
    return;
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _setupFlutterNotifications();

    runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> _setupFlutterNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maintenance Chatbot App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: AuthGate(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/landing': (context) => LandingPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return MainNavigation();
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    MaintenanceLogPage(),
    ChatbotPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchUserRole();
  }
    Future<void> _fetchUserRole() async {
    await Provider.of<UserProvider>(context, listen: false).fetchUserRole();
  }

  Future<void> _initNotifications() async {
    final authStatus = await _notificationService.requestNotificationPermissions();
    if (authStatus == AuthorizationStatus.authorized || authStatus == AuthorizationStatus.provisional) {
      final token = await _notificationService.getFCMToken();
      print("FCM Token: $token");
      if (token != null) {
        final success = await _notificationService.sendTokenToServer(token);
      }
    }

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        final notification = message.notification!;
        final android = message.notification?.android;
        if (android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.high,
                priority: Priority.high,
                showWhen: true,
              ),
            ),
          );
        } else {
          _showNotificationDialog(notification.title ?? 'No Title', notification.body ?? 'No Body');
        }
      }
    });
  }

  void _showNotificationDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with top navigation bar
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Study Abroad', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _onItemTapped(0),
                    child: Text('Maintenance', style: TextStyle(color: _selectedIndex == 0 ? Colors.white : Colors.grey[400])),
                  ),
                  SizedBox(width: 20),
                  TextButton(
                    onPressed: () => _onItemTapped(1),
                    child: Text('Chat', style: TextStyle(color: _selectedIndex == 1 ? Colors.white : Colors.grey[400])),
                  ),
                  SizedBox(width: 20),
                  TextButton(
                    onPressed: () => _onItemTapped(2),
                    child: Text('Profile', style: TextStyle(color: _selectedIndex == 2 ? Colors.white : Colors.grey[400])),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: _pages[_selectedIndex],
      );
    } else {
      // Android version with bottom navigation bar
      return Scaffold(
        //appBar: AppBar(
         // backgroundColor: Colors.grey[900],
         // title: const Text('Study Abroad', style: TextStyle(color: Colors.white)),
          //centerTitle: true,
      // ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[500],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
            BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
        ),
      );
    }
  }
}