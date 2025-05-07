import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Ensure this import is present
import 'home_page.dart'; // Ensure that this import is correct
import 'maintenance_log_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for all supported platforms
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Optionally handle error (e.g., navigate to an error page, show a message)
  }

  runApp(MyApp());
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
      home: AuthGate(), // Control the app's flow based on auth status
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
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
          return MainNavigation(); // User is authenticated
        } else {
          return LoginPage(); // User is not authenticated
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
  int _selectedIndex = 1; // Start with the ChatbotPage/HomePage as selected

  final List<Widget> _pages = [
    MaintenanceLogPage(),
    ChatbotPage(), // Changed from ChatbotPage to HomePage
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index when a tab is tapped
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Study Abroad', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex], // Display the current page based on the selected index
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[500],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Handle item taps
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