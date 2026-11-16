package org.entner.HitzeV.data

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.entner.HitzeV.push.PushMessagingClient
import org.entner.HitzeV.push.PushState
import org.entner.HitzeV.push.PushStateStore
import org.entner.HitzeV.push.PushSyncResult
import org.entner.HitzeV.push.PushTimeoutException
import kotlin.coroutines.cancellation.CancellationException

/** GKZ subscribed by app versions before push contract v2 (stored in the main preferences file). */
interface LegacySubscriptionSource {
    suspend fun readLegacyGkz(): Set<String>
    suspend fun clearLegacyState()
}

fun interface PushRetryScheduler {
    /** [replaceExisting] = false keeps an already queued run (and its backoff). */
    fun schedule(replaceExisting: Boolean)
}

/**
 * Keeps the FCM topic subscriptions of this installation in line with the desired GKZ set
 * (docs/push-contract-v2.md). Topic (un)subscription never depends on POST_NOTIFICATIONS.
 */
class SubscriptionManager(
    private val client: PushMessagingClient,
    private val store: PushStateStore,
    private val legacySource: LegacySubscriptionSource,
    private val retryScheduler: PushRetryScheduler
) {
    private val mutex = Mutex()

    /**
     * [complete] = false: some push-enabled worksite has no GKZ yet, so [desiredGkz] is only part of the
     * wanted set. Then additions happen but nothing already requested, subscribed or legacy is dropped.
     */
    suspend fun sync(desiredGkz: Set<String>, enabled: Boolean, complete: Boolean = true): PushSyncResult = try {
        mutex.withLock { syncLocked(desiredGkz, enabled, complete) }
    } catch (error: CancellationException) {
        // A sync cut short must still converge; the worker reconciles whatever desired state was stored.
        scheduleRetry(replaceExisting = true)
        throw error
    }

    private suspend fun syncLocked(desiredGkz: Set<String>, enabled: Boolean, complete: Boolean): PushSyncResult {
        val known = desiredGkz.mapNotNull(::normalizeGkz).toSet()
        val invalid = desiredGkz.filter { normalizeGkz(it) == null }.toSet()
        var requested = if (enabled) known else emptySet()
        val outcome = try {
            importLegacyGkzIfNeeded()
            store.update { state ->
                val desired = effectiveDesiredGkz(known, enabled, complete, state)
                requested = if (enabled) desired else emptySet()
                val wasActive = state.targetGkz.isNotEmpty() || state.subscribedGkz.isNotEmpty()
                state.copy(
                    desiredGkz = desired,
                    enabled = enabled,
                    hasSynced = true,
                    deleteTokenPending = requested.isEmpty() && (state.deleteTokenPending || wasActive)
                )
            }
            reconcile(forceResubscribe = false, includeMigration = false)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Outcome(failedGkz = requested, errorMessage = describe("sync", error), pendingWork = true)
        }
        if (outcome.pendingWork) scheduleRetry(replaceExisting = true)
        val invalidRequested = if (enabled) invalid else emptySet()
        return PushSyncResult(
            failedGkz = outcome.failedGkz + invalidRequested,
            errorMessage = outcome.errorMessage
                ?: invalidRequested.takeIf { it.isNotEmpty() }?.let { "Invalid GKZ: ${it.sorted()}" }
        )
    }

    /**
     * Full pass for app start, token refresh and retries: re-subscribes every desired topic (idempotent),
     * runs the legacy-topic migration and the deferred deleteToken. Returns true when nothing is left to retry.
     */
    suspend fun runMaintenance(): Boolean = mutex.withLock {
        try {
            !reconcile(forceResubscribe = true, includeMigration = true).pendingWork
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            false
        }
    }

    /** App start: queue a maintenance pass unless one is already waiting. */
    fun requestResync() = scheduleRetry(replaceExisting = false)

    /** New FCM token: subscriptions of the old token are gone, so resubscribe now. */
    fun onTokenRefreshed() = scheduleRetry(replaceExisting = true)

    /** GKZ for which a received v2 push should be shown; null before the app ever synced. */
    suspend fun activeGkzOrNull(): Set<String>? = store.read().takeIf(PushState::hasSynced)?.targetGkz

    /** Whether a legacy push for [gkz] delivered to the app (foreground) should be shown. */
    suspend fun shouldShowLegacyPush(gkz: String?): Boolean = legacyPushVisible(gkz, store.read())

    private suspend fun reconcile(forceResubscribe: Boolean, includeMigration: Boolean): Outcome {
        importLegacyGkzIfNeeded()
        var state = store.read()
        val target = state.targetGkz
        val failed = linkedSetOf<String>()
        val errors = mutableListOf<String>()
        var pending = false
        var offline = false

        if (target.isNotEmpty()) {
            val token = try {
                client.token().takeIf { it.isNotBlank() } ?: throw IllegalStateException("empty FCM token")
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                return Outcome(failedGkz = target, errorMessage = describe("getToken", error), pendingWork = true)
            }
            if (token != state.token) {
                state = store.update { it.copy(token = token, subscribedGkz = emptySet(), deleteTokenPending = false) }
            }
            val toSubscribe = if (forceResubscribe) target else target - state.subscribedGkz
            for (gkz in toSubscribe.sorted()) {
                if (offline) {
                    failed += gkz
                    continue
                }
                try {
                    client.subscribe(v2Topic(gkz))
                    state = store.update { it.copy(subscribedGkz = it.subscribedGkz + gkz) }
                } catch (error: CancellationException) {
                    throw error
                } catch (error: Exception) {
                    failed += gkz
                    errors += describe("subscribe ${v2Topic(gkz)}", error)
                    offline = error is PushTimeoutException
                }
            }
            pending = failed.isNotEmpty()
        }

        for (gkz in (state.subscribedGkz - target).sorted()) {
            if (offline) {
                pending = true
                break
            }
            try {
                client.unsubscribe(v2Topic(gkz))
                state = store.update { it.copy(subscribedGkz = it.subscribedGkz - gkz) }
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                pending = true
                offline = error is PushTimeoutException
            }
        }

        val migrationCandidates = migrationCandidates(state)
        if (migrationCandidates.isNotEmpty()) {
            if (!includeMigration || offline) {
                pending = true
            } else {
                for (gkz in migrationCandidates) {
                    // Keep receiving legacy pushes until the v2 topic for this GKZ is confirmed.
                    if (gkz in target && gkz !in state.subscribedGkz) {
                        pending = true
                        continue
                    }
                    if (unsubscribeLegacyTopics(gkz)) {
                        state = store.update {
                            it.copy(migratedGkz = it.migratedGkz + gkz, legacyGkz = it.legacyGkz - gkz)
                        }
                    } else {
                        pending = true
                        break
                    }
                }
            }
        }

        val canDeleteToken = target.isEmpty() && state.deleteTokenPending &&
            state.subscribedGkz.isEmpty() && migrationCandidates(state).isEmpty()
        if (canDeleteToken) {
            try {
                client.deleteToken()
                store.update { it.copy(token = null, subscribedGkz = emptySet(), deleteTokenPending = false) }
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                pending = true
            }
        } else if (target.isEmpty() && state.deleteTokenPending) {
            pending = true
        }

        return Outcome(
            failedGkz = failed,
            errorMessage = errors.takeIf { failed.isNotEmpty() }?.joinToString("; "),
            pendingWork = pending
        )
    }

    private fun migrationCandidates(state: PushState): List<String> =
        if (!state.hasSynced) {
            emptyList()
        } else {
            ((state.legacyGkz + state.targetGkz) - state.migratedGkz).sorted()
        }

    private suspend fun unsubscribeLegacyTopics(gkz: String): Boolean =
        legacyTopics(gkz).all { topic ->
            try {
                client.unsubscribe(topic)
                true
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                false
            }
        }

    private suspend fun importLegacyGkzIfNeeded() {
        if (store.read().legacyImported) return
        val legacy = legacySource.readLegacyGkz().mapNotNull(::normalizeGkz).toSet()
        store.update { it.copy(legacyGkz = it.legacyGkz + legacy, legacyImported = true) }
        legacySource.clearLegacyState()
    }

    private fun scheduleRetry(replaceExisting: Boolean) {
        try {
            retryScheduler.schedule(replaceExisting)
        } catch (_: Exception) {
            // The next app start schedules maintenance again.
        }
    }

    private fun describe(operation: String, error: Exception): String =
        "$operation failed: ${error::class.java.simpleName}${error.message?.let { ": $it" }.orEmpty()}"

    private data class Outcome(val failedGkz: Set<String>, val errorMessage: String?, val pendingWork: Boolean)

    companion object {
        /** All languages that ever had legacy `warngebiet_<GKZ>_<lang>` topics. */
        val LEGACY_LANGUAGE_CODES = listOf(
            "bg", "da", "de", "en", "et", "fi", "fr", "el", "ga", "it", "hr", "lv", "lt",
            "mt", "nl", "pl", "pt", "ro", "sv", "sk", "sl", "es", "cs", "hu", "tr"
        )

        private val WHITESPACE = Regex("""\s+""")
        private val TOPIC_SAFE = Regex("""[A-Za-z0-9\-_.~%]+""")

        fun normalizeGkz(raw: String): String? =
            raw.replace(WHITESPACE, "").takeIf { it.isNotEmpty() && TOPIC_SAFE.matches(it) }

        /**
         * The GKZ set to store as desired. While the worksite list is incomplete, keep everything that is
         * already requested, subscribed or still subscribed by an older app version (removals wait).
         */
        fun effectiveDesiredGkz(known: Set<String>, enabled: Boolean, complete: Boolean, state: PushState): Set<String> =
            if (complete || !enabled) known else known + state.targetGkz + state.subscribedGkz + state.legacyGkz

        /**
         * Once the v2 topic of a GKZ is confirmed the v2 push for the same warning follows, so the legacy
         * duplicate is dropped. Legacy pushes for municipalities no longer wanted are dropped as well.
         */
        fun legacyPushVisible(gkz: String?, state: PushState): Boolean {
            val normalized = gkz?.let(::normalizeGkz) ?: return true
            if (!state.hasSynced) return true
            return normalized in state.targetGkz && normalized !in state.subscribedGkz
        }

        fun v2Topic(gkz: String): String = "warngebiet_v2_$gkz"

        fun legacyTopics(gkz: String): List<String> =
            listOf("warngebiet_$gkz") + LEGACY_LANGUAGE_CODES.map { "warngebiet_${gkz}_$it" }
    }
}
