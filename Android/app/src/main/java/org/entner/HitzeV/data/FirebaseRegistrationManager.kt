package org.entner.HitzeV.data

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await

class FirebaseRegistrationManager(private val context: Context) {
    suspend fun registerForPushNotificationsIfNeeded(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            throw FirebaseRegistrationError.PermissionDenied
        }

        val token = FirebaseMessaging.getInstance().token.await()
        if (token.isBlank()) {
            throw FirebaseRegistrationError.TokenMissing
        }
        return token
    }

    suspend fun deregisterFromFirebase() {
        FirebaseMessaging.getInstance().deleteToken().await()
    }
}

sealed class FirebaseRegistrationError(message: String) : Exception(message) {
    data object PermissionDenied : FirebaseRegistrationError("Push-Berechtigung wurde nicht erteilt.")
    data object TokenMissing : FirebaseRegistrationError("FCM Token wurde nicht geliefert.")
}
