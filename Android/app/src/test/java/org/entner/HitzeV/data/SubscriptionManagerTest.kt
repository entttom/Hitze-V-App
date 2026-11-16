package org.entner.HitzeV.data

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runTest
import org.entner.HitzeV.push.PushState
import org.entner.HitzeV.push.PushStateStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.IOException

class SubscriptionManagerTest {
    private val client = FakePushClient()
    private val store = FakePushStateStore()
    private val legacy = FakeLegacySource()
    private val scheduled = mutableListOf<Boolean>()
    private val manager = SubscriptionManager(client, store, legacy) { replace -> scheduled += replace }

    private fun v2(gkz: String) = "sub:warngebiet_v2_$gkz"

    @Test
    fun subscribesOnlyV2TopicsAndNormalizesGkz() = runTest {
        val result = manager.sync(setOf(" 601 01", "30101"), enabled = true)

        assertTrue(result.isSuccess)
        assertEquals(setOf("warngebiet_v2_60101", "warngebiet_v2_30101"), client.subscribed)
        assertEquals(setOf("60101", "30101"), store.flow.value.subscribedGkz)
        assertEquals("token-1", store.flow.value.token)
        assertTrue(client.calls.none { it.startsWith("sub:") && !it.startsWith("sub:warngebiet_v2_") })
    }

    @Test
    fun syncDefersMigrationToMaintenanceWhichUnsubscribesAll26LegacyTopicsOnce() = runTest {
        manager.sync(setOf("60101"), enabled = true)
        assertTrue(client.calls.none { it.startsWith("unsub:") })
        assertEquals(listOf(true), scheduled)

        assertTrue(manager.runMaintenance())
        val legacyCalls = client.calls.filter { it.startsWith("unsub:warngebiet_60101") }
        assertEquals(26, legacyCalls.size)
        assertTrue("unsub:warngebiet_60101" in legacyCalls)
        assertTrue(SubscriptionManager.LEGACY_LANGUAGE_CODES.all { "unsub:warngebiet_60101_$it" in legacyCalls })
        assertEquals(setOf("60101"), store.flow.value.migratedGkz)

        client.calls.clear()
        assertTrue(manager.runMaintenance())
        assertTrue(client.calls.none { it.startsWith("unsub:") })
        assertEquals(listOf(v2("60101")), client.calls.filter { it.startsWith("sub:") })
    }

    @Test
    fun migrationRetriesUntilEveryLegacyTopicIsGone() = runTest {
        manager.sync(setOf("60101"), enabled = true)
        client.failingTopics += "warngebiet_60101_hu"
        assertFalse(manager.runMaintenance())
        assertTrue(store.flow.value.migratedGkz.isEmpty())

        client.failingTopics.clear()
        assertTrue(manager.runMaintenance())
        assertEquals(setOf("60101"), store.flow.value.migratedGkz)
    }

    @Test
    fun importsLegacySubscriptionsAndMigratesThemEvenIfNoLongerDesired() = runTest {
        legacy.gkz = setOf("10101")
        manager.sync(setOf("60101"), enabled = true)
        assertTrue(legacy.cleared)

        assertTrue(manager.runMaintenance())
        assertTrue(client.calls.contains("unsub:warngebiet_10101_de"))
        assertEquals(setOf("10101", "60101"), store.flow.value.migratedGkz)
        assertTrue(store.flow.value.legacyGkz.isEmpty())
    }

    @Test
    fun noMigrationBeforeTheFirstSync() = runTest {
        legacy.gkz = setOf("10101")
        assertTrue(manager.runMaintenance())
        assertTrue(client.calls.isEmpty())
        assertEquals(setOf("10101"), store.flow.value.legacyGkz)
    }

    @Test
    fun keepsLegacyTopicsUntilV2SubscriptionIsConfirmed() = runTest {
        client.failingTopics += "warngebiet_v2_60101"
        val result = manager.sync(setOf("60101"), enabled = true)
        assertEquals(setOf("60101"), result.failedGkz)
        assertNotNull(result.errorMessage)

        assertFalse(manager.runMaintenance())
        assertTrue(client.calls.none { it.startsWith("unsub:warngebiet_60101") })
    }

    @Test
    fun removedGkzIsUnsubscribed() = runTest {
        manager.sync(setOf("60101", "30101"), enabled = true)
        client.calls.clear()

        manager.sync(setOf("60101"), enabled = true)

        assertEquals(listOf("token", "unsub:warngebiet_v2_30101"), client.calls)
        assertEquals(setOf("60101"), store.flow.value.subscribedGkz)
    }

    @Test
    fun disablingUnsubscribesAllAndDeletesTokenOnlyOnce() = runTest {
        manager.sync(setOf("60101"), enabled = true)
        manager.runMaintenance()

        val result = manager.sync(setOf("60101"), enabled = false)

        assertTrue(result.isSuccess)
        assertTrue(client.calls.contains("unsub:warngebiet_v2_60101"))
        assertEquals(1, client.deleteTokenCalls)
        assertNull(store.flow.value.token)

        manager.sync(emptySet(), enabled = true)
        manager.sync(emptySet(), enabled = false)
        manager.runMaintenance()
        assertEquals(1, client.deleteTokenCalls)
    }

    @Test
    fun emptySyncOnFreshInstallTouchesNothing() = runTest {
        val result = manager.sync(emptySet(), enabled = true)
        assertTrue(result.isSuccess)
        assertTrue(client.calls.isEmpty())
        assertTrue(scheduled.isEmpty())
    }

    @Test
    fun deleteTokenWaitsForPendingLegacyMigration() = runTest {
        legacy.gkz = setOf("10101")
        manager.sync(emptySet(), enabled = false)
        assertEquals(0, client.deleteTokenCalls)

        manager.sync(setOf("60101"), enabled = true)
        manager.sync(setOf("60101"), enabled = false)
        assertEquals(0, client.deleteTokenCalls)

        assertTrue(manager.runMaintenance())
        assertEquals(1, client.deleteTokenCalls)
    }

    @Test
    fun tokenFailureReportsEveryGkzWithoutThrowing() = runTest {
        client.tokenError = IOException("SERVICE_NOT_AVAILABLE")
        val result = manager.sync(setOf("60101", "30101"), enabled = true)

        assertEquals(setOf("60101", "30101"), result.failedGkz)
        assertNotNull(result.errorMessage)
        assertEquals(listOf(true), scheduled)

        client.tokenError = null
        assertTrue(manager.runMaintenance())
        assertEquals(setOf("60101", "30101"), store.flow.value.subscribedGkz)
    }

    @Test
    fun timeoutStopsFurtherNetworkCallsInThisRun() = runTest {
        client.timeoutTopics += "warngebiet_v2_10101"
        val result = manager.sync(setOf("10101", "20202", "30303"), enabled = true)

        assertEquals(setOf("10101", "20202", "30303"), result.failedGkz)
        assertEquals(listOf(v2("10101")), client.calls.filter { it.startsWith("sub:") })
    }

    @Test
    fun tokenRotationResubscribesEverything() = runTest {
        manager.sync(setOf("60101", "30101"), enabled = true)
        client.subscribed.clear()
        client.token = "token-2"

        manager.sync(setOf("60101", "30101"), enabled = true)

        assertEquals(setOf("warngebiet_v2_60101", "warngebiet_v2_30101"), client.subscribed)
        assertEquals("token-2", store.flow.value.token)
    }

    @Test
    fun maintenanceResubscribesAllDesiredTopics() = runTest {
        manager.sync(setOf("60101"), enabled = true)
        client.subscribed.clear()

        assertTrue(manager.runMaintenance())
        assertTrue("warngebiet_v2_60101" in client.subscribed)
    }

    @Test
    fun invalidGkzIsReportedAsFailed() = runTest {
        val result = manager.sync(setOf("60101", "bad/topic"), enabled = true)
        assertEquals(setOf("bad/topic"), result.failedGkz)
        assertEquals(setOf("warngebiet_v2_60101"), client.subscribed)
    }

    @Test
    fun activeGkzReflectsTargetSet() = runTest {
        assertNull(manager.activeGkzOrNull())
        manager.sync(setOf("60101"), enabled = true)
        assertEquals(setOf("60101"), manager.activeGkzOrNull())
        manager.sync(setOf("60101"), enabled = false)
        assertEquals(emptySet<String>(), manager.activeGkzOrNull())
    }

    @Test
    fun storeFailureBecomesResultNotException() = runTest {
        val failing = object : PushStateStore {
            override val state: Flow<PushState> = MutableStateFlow(PushState())
            override suspend fun update(transform: (PushState) -> PushState): PushState = throw IOException("disk full")
        }
        val result = SubscriptionManager(client, failing, legacy) { }.sync(setOf("60101"), enabled = true)
        assertEquals(setOf("60101"), result.failedGkz)
        assertNotNull(result.errorMessage)
    }

    @Test
    fun incompleteSyncAddsNewGkzButKeepsRemovedOnes() = runTest {
        manager.sync(setOf("60101", "30101"), enabled = true)
        client.calls.clear()

        val result = manager.sync(setOf("60101", "10101"), enabled = true, complete = false)

        assertTrue(result.isSuccess)
        assertEquals(listOf("token", v2("10101")), client.calls)
        assertEquals(setOf("60101", "30101", "10101"), store.flow.value.subscribedGkz)
        assertEquals(setOf("60101", "30101", "10101"), store.flow.value.desiredGkz)

        client.calls.clear()
        manager.sync(setOf("60101", "10101"), enabled = true, complete = true)
        assertEquals(listOf("token", "unsub:warngebiet_v2_30101"), client.calls)
        assertEquals(setOf("60101", "10101"), store.flow.value.subscribedGkz)
    }

    @Test
    fun incompleteSyncKeepsRequestedGkzWhoseSubscribeIsStillPending() = runTest {
        client.failingTopics += "warngebiet_v2_30101"
        manager.sync(setOf("60101", "30101"), enabled = true)

        manager.sync(setOf("60101"), enabled = true, complete = false)

        assertEquals(setOf("60101", "30101"), store.flow.value.desiredGkz)
    }

    @Test
    fun incompleteSyncWithoutAnyKnownGkzSubscribesLegacyGkzAndKeepsTheirLegacyTopics() = runTest {
        legacy.gkz = setOf("10101")

        val result = manager.sync(emptySet(), enabled = true, complete = false)

        assertTrue(result.isSuccess)
        assertEquals(setOf("warngebiet_v2_10101"), client.subscribed)
        assertTrue(client.calls.none { it.startsWith("unsub:") })
        assertEquals(0, client.deleteTokenCalls)
        assertFalse(store.flow.value.deleteTokenPending)
    }

    @Test
    fun incompleteSyncOnFreshInstallTouchesNothing() = runTest {
        val result = manager.sync(emptySet(), enabled = true, complete = false)
        assertTrue(result.isSuccess)
        assertTrue(client.calls.isEmpty())
        assertFalse(store.flow.value.deleteTokenPending)
    }

    @Test
    fun disablingIgnoresIncompleteness() = runTest {
        manager.sync(setOf("60101"), enabled = true)
        manager.sync(emptySet(), enabled = false, complete = false)
        assertTrue(client.calls.contains("unsub:warngebiet_v2_60101"))
        assertTrue(store.flow.value.subscribedGkz.isEmpty())
    }

    @Test
    fun effectiveDesiredGkzOnlyGrowsWhileIncomplete() {
        val state = PushState(
            desiredGkz = setOf("30101"),
            enabled = true,
            subscribedGkz = setOf("20101"),
            legacyGkz = setOf("10101")
        )
        assertEquals(
            setOf("60101", "30101", "20101", "10101"),
            SubscriptionManager.effectiveDesiredGkz(setOf("60101"), enabled = true, complete = false, state = state)
        )
        assertEquals(
            setOf("60101"),
            SubscriptionManager.effectiveDesiredGkz(setOf("60101"), enabled = true, complete = true, state = state)
        )
        assertEquals(
            setOf("60101"),
            SubscriptionManager.effectiveDesiredGkz(setOf("60101"), enabled = false, complete = false, state = state)
        )
        // Previously desired only counts while push was enabled.
        assertEquals(
            setOf("60101", "20101", "10101"),
            SubscriptionManager.effectiveDesiredGkz(
                setOf("60101"), enabled = true, complete = false, state = state.copy(enabled = false)
            )
        )
    }

    @Test
    fun cancelledSyncSchedulesRetryThatFinishesTheSubscription() = runTest {
        val started = CompletableDeferred<Unit>()
        client.beforeSubscribe = {
            started.complete(Unit)
            awaitCancellation()
        }
        val job = launch { manager.sync(setOf("60101"), enabled = true) }
        started.await()

        job.cancelAndJoin()

        assertEquals(listOf(true), scheduled)
        assertTrue(store.flow.value.subscribedGkz.isEmpty())
        client.beforeSubscribe = null
        assertTrue(manager.runMaintenance())
        assertEquals(setOf("60101"), store.flow.value.subscribedGkz)
    }

    @Test
    fun cancelledWhileWaitingForTheLockStillSchedulesRetry() = runTest {
        val started = CompletableDeferred<Unit>()
        client.beforeSubscribe = {
            started.complete(Unit)
            awaitCancellation()
        }
        val first = launch { manager.sync(setOf("60101"), enabled = true) }
        started.await()
        val second = launch { manager.sync(setOf("60101", "30101"), enabled = true) }
        testScheduler.runCurrent()

        second.cancelAndJoin()
        first.cancelAndJoin()

        assertEquals(listOf(true, true), scheduled)
    }

    @Test
    fun legacyPushIsShownUntilTheV2TopicOfItsGkzIsConfirmed() {
        val beforeFirstSync = PushState(legacyGkz = setOf("60101"))
        assertTrue(SubscriptionManager.legacyPushVisible("60101", beforeFirstSync))

        val pending = PushState(desiredGkz = setOf("60101"), enabled = true, hasSynced = true)
        assertTrue(SubscriptionManager.legacyPushVisible("60101", pending))
        assertTrue(SubscriptionManager.legacyPushVisible(" 601 01", pending))

        val confirmed = pending.copy(subscribedGkz = setOf("60101"))
        assertFalse(SubscriptionManager.legacyPushVisible("60101", confirmed))

        assertFalse(SubscriptionManager.legacyPushVisible("30101", confirmed))
        assertFalse(SubscriptionManager.legacyPushVisible("60101", pending.copy(enabled = false)))
        assertTrue(SubscriptionManager.legacyPushVisible(null, confirmed))
    }

    @Test
    fun shouldShowLegacyPushReadsTheStore() = runTest {
        manager.sync(setOf("60101"), enabled = true)
        assertFalse(manager.shouldShowLegacyPush("60101"))
    }
}
