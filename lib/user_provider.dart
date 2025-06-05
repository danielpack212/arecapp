import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String _userRole = '';
  String _userId = '';
  bool _isLoaded = false;

  String get userRole => _userRole;
  String get userId => _userId;
  bool get isLoaded => _isLoaded;

  Future<void> ensureUserRoleLoaded() async {
    if (!_isLoaded) {
      await fetchUserRole();
    }
  }

  Future<void> fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }
    
    _userId = user.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .get();

    if (userDoc.exists) {
      _userRole = userDoc['role'] ?? '';
    } else {
      _userRole = ''; // Ensure role is empty if document doesn't exist
    }
    
    _isLoaded = true;
    notifyListeners();
    print('User role fetched: $_userRole'); // Add this log
  }

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
    print('User role set: $_userRole'); // Add this log
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  void resetLoadedState() {
    _isLoaded = false;
    _userRole = '';
    _userId = '';
    notifyListeners();
  }
}