package org.entner.HitzeV.push

import com.google.android.gms.tasks.Task
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull
import java.io.IOException

/** Seam over FirebaseMessaging so SubscriptionManager can be unit-tested. */
interface PushMessagingClient {
    suspend fun token(): String
    suspend fun subscribe(topic: String)
    suspend fun unsubscribe(topic: String)
    suspend fun deleteToken()
}

class PushTimeoutException(operation: String) : IOException("$operation timed out")

// firebase-messaging 25.1 deprecates getToken()/deleteToken() in favour of register()/unregister(),
// which do not return the token. The token string is what detects rotation (and so the need to
// re-subscribe), so the still-supported deprecated calls are used deliberately.
@Suppress("DEPRECATION")
class FirebasePushMessagingClient(
    private val timeoutMillis: Long = 20_000
) : PushMessagingClient {
    // getInstance() itself throws when Firebase is not initialised (e.g. missing google-services config).
    private val messaging: FirebaseMessaging get() = FirebaseMessaging.getInstance()

    override suspend fun token(): String = awaitTask("getToken") { messaging.token }

    override suspend fun subscribe(topic: String) {
        awaitTask("subscribe $topic") { messaging.subscribeToTopic(topic) }
    }

    override suspend fun unsubscribe(topic: String) {
        awaitTask("unsubscribe $topic") { messaging.unsubscribeFromTopic(topic) }
    }

    override suspend fun deleteToken() {
        awaitTask("deleteToken") { messaging.deleteToken() }
    }

    // Offline, topic tasks stay pending until connectivity returns; withTimeoutOrNull (not withTimeout)
    // so a timeout surfaces as an IOException instead of a CancellationException.
    private suspend fun <T> awaitTask(operation: String, task: () -> Task<T>): T {
        val result = withTimeoutOrNull(timeoutMillis) { Holder(task().await()) }
            ?: throw PushTimeoutException(operation)
        return result.value
    }

    private class Holder<T>(val value: T)
}
