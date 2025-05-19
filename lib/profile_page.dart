import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedRole;

  final List<String> _roles = ['Maintenance Technician', 'Energy Expert'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;
      if (userData != null) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _selectedRole = userData['role'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: isWeb
          ? null
          : AppBar(
              title: Text('Profile Page', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[900],
              centerTitle: true,
            ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 4,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[300],
                                child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _nameController,
                              decoration: _inputDecoration('Name'),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _phoneController,
                              decoration: _inputDecoration('Phone Number'),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue;
                                });
                              },
                              items: _roles.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              decoration: _inputDecoration('Role'),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                                  'name': _nameController.text,
                                  'phone': _phoneController.text,
                                  'role': _selectedRole,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Profile updated successfully')),
                                );
                              },
                              child: Text('Update Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[900],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                minimumSize: Size(double.infinity, 50),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: Icon(Icons.logout),
                              label: Text('Log Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                minimumSize: Size(double.infinity, 50),
                              ),
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[800]),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}