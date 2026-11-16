package org.entner.HitzeV.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.push.DataStorePushStateStore
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/** First start after updating from the production app, which stored only `subscription_manager.*` push state. */
class UpgradeFromProductionTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private val ioScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val appPreferences = dataStore("hitze_v_app")
    private val appStorage = AppStorage(appPreferences)
    private val pushStore = DataStorePushStateStore(dataStore("hitze_v_push_state"))
    private val client = FakePushClient()
    private val scheduled = mutableListOf<Boolean>()
    private val manager = SubscriptionManager(client, pushStore, appStorage) { replace -> scheduled += replace }

    private fun dataStore(name: String): DataStore<Preferences> =
        PreferenceDataStoreFactory.create(scope = ioScope, produceFile = { File(tmp.root, "$name.preferences_pb") })

    @After
    fun tearDown() {
        ioScope.cancel()
    }

    private suspend fun seedProductionState() {
        appPreferences.edit {
            // Production worksites have no municipalityId; it is filled in by the first refresh.
            it[stringPreferencesKey("dashboard.worksites.v1")] =
                """[{"id":"a","name":"Graz","address":"Hauptplatz 1","latitude":47.07,"longitude":15.44},""" +
                """{"id":"b","name":"Wien","latitude":48.2,"longitude":16.37}]"""
            it[booleanPreferencesKey("push.notifications.enabled")] = true
            it[stringPreferencesKey("dashboard.language")] = "de"
            it[stringSetPreferencesKey("subscription_manager.subscribedMunicipalityIDs")] = setOf("60101", "90001")
            it[stringPreferencesKey("subscription_manager.lastSubscribedLanguageCode")] = "de"
        }
    }

    private suspend fun dashboardSync(loadedGkz: Map<String, String>) {
        appStorage.saveWorksites(DashboardViewModel.mergeMunicipalityIds(appStorage.worksites.first(), loadedGkz))
        val request = DashboardViewModel.pushSyncRequest(
            appStorage.worksites.first(),
            appStorage.disabledPushWorksiteIds.first()
        )
        manager.sync(request.knownGkz, appStorage.isPushNotificationsEnabled.first(), request.complete)
    }

    private fun legacyUnsubscribes(gkz: String) = client.calls.filter { it.startsWith("unsub:warngebiet_${gkz}") }

    @Test
    fun appStartMaintenanceAndTokenRefreshTearNothingDownBeforeTheFirstSync() = runTest {
        seedProductionState()

        manager.requestResync()
        assertTrue(manager.runMaintenance())
        manager.onTokenRefreshed()
        assertTrue(manager.runMaintenance())

        assertEquals(listOf(false, true), scheduled)
        assertTrue(client.calls.isEmpty())
        val state = pushStore.read()
        assertFalse(state.hasSynced)
        assertEquals(setOf("60101", "90001"), state.legacyGkz)
        assertTrue(appStorage.readLegacyGkz().isEmpty())
        // No legacy push is suppressed before the first v2 sync.
        assertTrue(manager.shouldShowLegacyPush("60101"))
    }

    @Test
    fun firstSyncWithAWorksiteStillWithoutGkzSubscribesV2BeforeDroppingAnyLegacyTopic() = runTest {
        seedProductionState()
        manager.runMaintenance()

        // Worksite "b" (Wien) failed to load, so its GKZ is still unknown.
        client.failingTopics += "warngebiet_v2_90001"
        dashboardSync(mapOf("a" to "60101"))

        assertEquals(0, client.deleteTokenCalls)
        assertTrue(client.calls.none { it.startsWith("unsub:") })
        assertEquals(setOf("60101", "90001"), pushStore.read().desiredGkz)
        assertEquals(setOf("60101"), pushStore.read().subscribedGkz)

        assertFalse(manager.runMaintenance())
        assertEquals(26, legacyUnsubscribes("60101").size)
        assertTrue(client.calls.indexOf("sub:warngebiet_v2_60101") < client.calls.indexOf("unsub:warngebiet_60101_de"))
        // v2 for Wien is not confirmed yet, so its legacy topics stay.
        assertTrue(legacyUnsubscribes("90001").isEmpty())
        assertTrue(manager.shouldShowLegacyPush("90001"))
        assertFalse(manager.shouldShowLegacyPush("60101"))

        client.failingTopics.clear()
        assertTrue(manager.runMaintenance())
        assertEquals(26, legacyUnsubscribes("90001").size)
        assertTrue(client.calls.lastIndexOf("sub:warngebiet_v2_90001") < client.calls.indexOf("unsub:warngebiet_90001_de"))

        dashboardSync(mapOf("b" to "90001"))
        assertEquals(setOf("60101", "90001"), pushStore.read().subscribedGkz)
        assertTrue(client.calls.none { it.startsWith("unsub:warngebiet_v2_") })
        assertEquals(0, client.deleteTokenCalls)
    }

    @Test
    fun firstSyncOfflineKeepsEverythingAndRetries() = runTest {
        seedProductionState()
        manager.runMaintenance()
        client.tokenError = java.io.IOException("SERVICE_NOT_AVAILABLE")

        dashboardSync(emptyMap())

        assertTrue(client.calls.none { it.startsWith("unsub:") || it.startsWith("sub:") })
        assertEquals(0, client.deleteTokenCalls)
        assertFalse(manager.runMaintenance())
        assertTrue(client.calls.none { it.startsWith("unsub:") })
        assertEquals(listOf(true), scheduled)
    }
}
