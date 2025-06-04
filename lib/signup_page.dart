import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedRole;
  String? _selectedBuilding;
  final List<String> _roles = ['Maintenance Technician', 'Energy Expert'];
  final List<String> _buildings = ['Hofburg', 'TUWien', 'The Loft','Freihaus'];

  bool _obscurePassword = true;
  String error = '';

  Future<void> _signup() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'email': _emailController.text.trim(),
        'fcmToken': 'uninitialized',
      };

      if (_selectedRole == 'Maintenance Technician') {
        userData['building'] = _selectedBuilding;
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation()),
      );
    } catch (e) {
      setState(() {
        error = 'Signup failed. Please try again. Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Sign Up', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(error, style: TextStyle(color: Colors.red)),
                        ),
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
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                            if (value != 'Maintenance Technician') {
                              _selectedBuilding = null;
                            }
                          });
                        },
                        decoration: _inputDecoration('Select Role'),
                        items: _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      if (_selectedRole == 'Maintenance Technician')
                        DropdownButtonFormField<String>(
                          value: _selectedBuilding,
                          onChanged: (value) {
                            setState(() {
                              _selectedBuilding = value;
                            });
                          },
                          decoration: _inputDecoration('Select Building'),
                          items: _buildings.map((building) {
                            return DropdownMenuItem<String>(
                              value: building,
                              child: Text(building),
                            );
                          }).toList(),
                        ),
                      if (_selectedRole == 'Maintenance Technician')
                        SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email'),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text('Sign Up'),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text("Already have an account? Login"),
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