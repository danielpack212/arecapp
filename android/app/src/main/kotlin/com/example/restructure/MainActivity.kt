package ARECC1.App  // Ensure this matches your app's package name

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle  // Import Bundle
import androidx.core.app.ActivityCompat // Import ActivityCompat for permission handling
import androidx.core.content.ContextCompat // Import to check permissions
import io.flutter.embedding.android.FlutterActivity  // Import FlutterActivity
import com.google.firebase.messaging.FirebaseMessaging // Import for Firebase Messaging

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel() // Call the method to create the notification channel
        askNotificationPermission() // Check and request notification permission for Android 13+
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create the NotificationChannel
            val channel = NotificationChannel(
                "default_channel_id", // The ID of the channel
                "Default Channel", // The user-visible name of the channel
                NotificationManager.IMPORTANCE_DEFAULT // The importance level
            )
            // Register the channel with the system
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun askNotificationPermission() {
        // Request notification permission for Android 13 and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1)
            }
        }
    }

    // Handle the result of the permission request
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                println("Notification permission granted")
            } else {
                println("Notification permission denied")
            }
        }
    }
}