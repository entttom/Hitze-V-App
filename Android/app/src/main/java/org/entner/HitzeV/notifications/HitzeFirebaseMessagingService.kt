package org.entner.HitzeV.notifications

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class HitzeFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        Log.d("HitzeV", "FCM message received: ${message.messageId ?: "n/a"}")
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("HitzeV", "FCM token updated: $token")
    }
}
