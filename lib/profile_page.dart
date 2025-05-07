import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfilePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb; // Use kIsWeb to check if the platform is web

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: isWeb
          ? null
          : AppBar(
              title: Text('Profile Page', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[900],
              centerTitle: true,
            ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: isWeb ? 600 : double.infinity, // Card width for web and mobile
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error fetching user data', style: TextStyle(color: Colors.red));
                } else if (!snapshot.hasData) {
                  return Text('No user data available', style: TextStyle(color: Colors.white));
                }

                final userData = snapshot.data!;

                return Card(
                  color: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Shrink card vertically
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[700],
                              child: Icon(Icons.person, size: 40, color: Colors.grey[500]),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['email'] ?? 'No email',
                                    style: TextStyle(fontSize: 24, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Name: ${userData['name'] ?? 'No name'}',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Role: ${userData['role'] ?? 'No role'}',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Phone Number: ${userData['phone'] ?? 'No phone number'}',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Email Address: ${userData['email'] ?? 'No email'}',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.logout),
                            label: Text('Log Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pushReplacementNamed('/login');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}