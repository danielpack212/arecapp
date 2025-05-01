// firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _android;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _ios;
    } else {
      throw UnsupportedError('Platform not supported: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyAJRQmQUKjMZJvhVVTAKExFyI8dVzoxOSE', // Your Android API Key
    appId: '1:449090184290:android:11c36da28fa31e0d6db41d', // Your Android App ID
    messagingSenderId: '449090184290', // Your Messaging Sender ID
    projectId: 'arec-app', // Your Project ID
    storageBucket: 'arec-app.appspot.com', // Your Storage Bucket
    authDomain: 'arec-app.firebaseapp.com', // Your Auth Domain
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyAJRQmQUKjMZJvhVVTAKExFyI8dVzoxOSE', // Your iOS API Key (same as Android)
    appId: '1:449090184290:ios:9e45fcb9ef95ab0e6db41d', // Your iOS App ID
    messagingSenderId: '449090184290', // Your Messaging Sender ID (same as Android)
    projectId: 'arec-app', // Your Project ID (same as Android)
    storageBucket: 'arec-app.appspot.com', // Your Storage Bucket (same as Android)
    authDomain: 'arec-app.firebaseapp.com', // Your Auth Domain (same as Android)
  );
}
