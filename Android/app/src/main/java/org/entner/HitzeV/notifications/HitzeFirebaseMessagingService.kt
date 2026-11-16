package org.entner.HitzeV.notifications

import android.app.LocaleManager
import android.content.res.Resources
import android.os.Build
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import org.entner.HitzeV.BuildConfig
import org.entner.HitzeV.R
import org.entner.HitzeV.appContainer
import org.entner.HitzeV.data.SubscriptionManager
import org.entner.HitzeV.push.PushMessage
import java.time.Instant

class HitzeFirebaseMessagingService : FirebaseMessagingService() {
    // Runs on Firebase's background executor, which allows blocking for a few seconds.
    override fun onMessageReceived(message: RemoteMessage) {
        val v2 = PushMessage.fromData(message.data)
        if (v2 != null) {
            showV2(v2)
        } else {
            showLegacy(message)
        }
    }

    @Suppress("OVERRIDE_DEPRECATION")
    override fun onNewToken(token: String) {
        onTokenChanged()
    }

    override fun onRegistered(token: String) {
        onTokenChanged()
    }

    private fun onTokenChanged() {
        if (BuildConfig.DEBUG) Log.d(TAG, "FCM token refreshed")
        applicationContext.appContainer.subscriptionManager.onTokenRefreshed()
    }

    private fun showV2(message: PushMessage) {
        val container = applicationContext.appContainer
        val active = readBlocking { container.subscriptionManager.activeGkzOrNull() }
        // A failed unsubscribe can leave a stale topic behind; never show warnings for removed sites.
        if (active != null && message.gkz !in active) return

        val storedLanguage = readBlocking { container.appStorage.appLanguageRawValue.first() }
        val rendered = container.pushCopyRenderer?.let { renderer ->
            val language = renderer.resolveLanguage(listOf(inAppLanguageCode(storedLanguage)))
            runCatching { renderer.render(message, language, Instant.now()) }.getOrNull()
        }
        HeatWarningNotifications.postWarning(
            context = this,
            gkz = message.gkz,
            title = rendered?.title ?: getString(R.string.app_name),
            body = rendered?.body ?: message.name,
            sentAt = message.sentAt
        )
    }

    private fun <T> readBlocking(read: suspend () -> T): T? =
        runBlocking { withTimeoutOrNull(READ_TIMEOUT_MILLIS) { runCatching { read() }.getOrNull() } }

    /** The language the app UI shows; a code missing from push-copy.json falls back per contract, not to the next source. */
    private fun inAppLanguageCode(storedLanguage: String?): String? {
        val explicit = storedLanguage?.takeUnless { it.isBlank() || it == SYSTEM_LANGUAGE }
        if (explicit != null) return explicit
        val perAppLocale = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getSystemService(LocaleManager::class.java)?.applicationLocales?.takeIf { !it.isEmpty }?.get(0)?.language
        } else {
            null
        }
        val systemLocale = Resources.getSystem().configuration.locales.takeIf { !it.isEmpty }?.get(0)?.language
        return perAppLocale ?: systemLocale
    }

    // Only foreground legacy pushes get here; in the background the system posts the `notification`
    // block itself (tag hitze-<GKZ>, id 0), so a duplicate next to the v2 one is possible there until
    // the legacy topics of that GKZ are unsubscribed.
    private fun showLegacy(message: RemoteMessage) {
        val body = message.notification?.body ?: message.data["body"] ?: return
        val title = message.notification?.title ?: message.data["title"] ?: getString(R.string.app_name)
        val gkz = message.data[LEGACY_GKZ_KEY]?.let(SubscriptionManager::normalizeGkz)
        val show = readBlocking { applicationContext.appContainer.subscriptionManager.shouldShowLegacyPush(gkz) }
        if (show == false) return
        HeatWarningNotifications.postLegacy(this, gkz, title, body)
    }

    private companion object {
        const val TAG = "HitzeV"
        const val SYSTEM_LANGUAGE = "system"
        const val READ_TIMEOUT_MILLIS = 3_000L
        const val LEGACY_GKZ_KEY = "gemeindenr"
    }
}
