// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.1.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/9.1.0/firebase-messaging.js');

// Initialize Firebase
firebase.initializeApp({
  apiKey: "AIzaSyAJRQmQUKjMZJvhVVTAKExFyI8dVzoxOSE",
  authDomain: "arec-app.firebaseapp.com",
  projectId: "arec-app",
  storageBucket: "arec-app.appspot.com",
  messagingSenderId: "449090184290",
  appId: "1:449090184290:web:43a6da94e5d1881c15dd3b",
  measurementId: "G-31Q830NBQQ"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message: ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: 'icon.png' // Adjust the icon path if necessary
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});