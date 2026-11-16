package org.entner.HitzeV.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.updateAndGet
import org.entner.HitzeV.push.PushMessagingClient
import org.entner.HitzeV.push.PushState
import org.entner.HitzeV.push.PushStateStore
import org.entner.HitzeV.push.PushTimeoutException
import java.io.IOException

internal class FakePushClient : PushMessagingClient {
    var token = "token-1"
    var tokenError: Exception? = null
    val failingTopics = mutableSetOf<String>()
    val timeoutTopics = mutableSetOf<String>()
    val subscribed = mutableSetOf<String>()
    val calls = mutableListOf<String>()
    var deleteTokenCalls = 0
    /** Runs before a subscribe completes, e.g. to suspend it until the caller is cancelled. */
    var beforeSubscribe: (suspend (String) -> Unit)? = null

    override suspend fun token(): String {
        calls += "token"
        tokenError?.let { throw it }
        return token
    }

    override suspend fun subscribe(topic: String) {
        calls += "sub:$topic"
        beforeSubscribe?.invoke(topic)
        if (topic in timeoutTopics) throw PushTimeoutException(topic)
        if (topic in failingTopics) throw IOException("SERVICE_NOT_AVAILABLE")
        subscribed += topic
    }

    override suspend fun unsubscribe(topic: String) {
        calls += "unsub:$topic"
        if (topic in failingTopics) throw IOException("SERVICE_NOT_AVAILABLE")
        subscribed -= topic
    }

    override suspend fun deleteToken() {
        calls += "deleteToken"
        deleteTokenCalls++
        subscribed.clear()
    }
}

internal class FakePushStateStore(initial: PushState = PushState()) : PushStateStore {
    val flow = MutableStateFlow(initial)
    override val state: Flow<PushState> = flow
    override suspend fun update(transform: (PushState) -> PushState): PushState = flow.updateAndGet(transform)
}

internal class FakeLegacySource(var gkz: Set<String> = emptySet()) : LegacySubscriptionSource {
    var cleared = false
    override suspend fun readLegacyGkz(): Set<String> = gkz
    override suspend fun clearLegacyState() {
        cleared = true
        gkz = emptySet()
    }
}
