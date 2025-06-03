import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String _userRole = '';
  String _userId = '';
  bool _isLoaded = false;

  String get userRole => _userRole;
  String get userId => _userId;

  Future<void> ensureUserRoleLoaded() async {
    if (!_isLoaded) {
      await fetchUserRole();
      _isLoaded = true;
    }
  }

  Future<void> fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _userRole = userDoc['role'] ?? '';
      } else {
        _userRole = ''; // Ensure role is empty if document doesn't exist
      }
    } else {
      _userId = '';
      _userRole = '';
    }
    _isLoaded = true;
    notifyListeners();
  }

  // You can add this method if you want to set the role programmatically
  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  // You can add this method if you want to set the user ID programmatically
  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  // Add this method to reset the loaded state if needed
  void resetLoadedState() {
    _isLoaded = false;
  }
}