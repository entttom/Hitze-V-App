package org.entner.HitzeV.push

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.core.handlers.ReplaceFileCorruptionHandler
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.io.IOException

data class PushState(
    val desiredGkz: Set<String> = emptySet(),
    val enabled: Boolean = false,
    val hasSynced: Boolean = false,
    /** FCM token that [subscribedGkz] belongs to. */
    val token: String? = null,
    val subscribedGkz: Set<String> = emptySet(),
    /** GKZ an older app version subscribed with legacy topics. */
    val legacyGkz: Set<String> = emptySet(),
    val legacyImported: Boolean = false,
    val migratedGkz: Set<String> = emptySet(),
    val deleteTokenPending: Boolean = false
) {
    val targetGkz: Set<String> get() = if (enabled) desiredGkz else emptySet()
}

interface PushStateStore {
    val state: Flow<PushState>
    suspend fun read(): PushState = state.first()
    suspend fun update(transform: (PushState) -> PushState): PushState
}

// Separate file so it can be excluded from backup/device transfer: topic subscriptions belong
// to this installation's FCM token and must never be restored onto another one.
private val Context.pushStateDataStore: DataStore<Preferences> by preferencesDataStore(
    name = PUSH_STATE_DATASTORE_NAME,
    corruptionHandler = ReplaceFileCorruptionHandler { emptyPreferences() }
)

const val PUSH_STATE_DATASTORE_NAME = "hitze_v_push_state"

class DataStorePushStateStore internal constructor(private val dataStore: DataStore<Preferences>) : PushStateStore {
    constructor(context: Context) : this(context.applicationContext.pushStateDataStore)

    override val state: Flow<PushState> = dataStore.data
        .catch { error -> if (error is IOException) emit(emptyPreferences()) else throw error }
        .map(::decode)

    override suspend fun update(transform: (PushState) -> PushState): PushState {
        var result = PushState()
        dataStore.edit { preferences ->
            result = transform(decode(preferences))
            encode(result, preferences)
        }
        return result
    }

    private fun decode(preferences: Preferences) = PushState(
        desiredGkz = preferences[Keys.desiredGkz].orEmpty(),
        enabled = preferences[Keys.enabled] ?: false,
        hasSynced = preferences[Keys.hasSynced] ?: false,
        token = preferences[Keys.token],
        subscribedGkz = preferences[Keys.subscribedGkz].orEmpty(),
        legacyGkz = preferences[Keys.legacyGkz].orEmpty(),
        legacyImported = preferences[Keys.legacyImported] ?: false,
        migratedGkz = preferences[Keys.migratedGkz].orEmpty(),
        deleteTokenPending = preferences[Keys.deleteTokenPending] ?: false
    )

    private fun encode(state: PushState, preferences: MutablePreferences) {
        preferences[Keys.desiredGkz] = state.desiredGkz
        preferences[Keys.enabled] = state.enabled
        preferences[Keys.hasSynced] = state.hasSynced
        if (state.token != null) preferences[Keys.token] = state.token else preferences.remove(Keys.token)
        preferences[Keys.subscribedGkz] = state.subscribedGkz
        preferences[Keys.legacyGkz] = state.legacyGkz
        preferences[Keys.legacyImported] = state.legacyImported
        preferences[Keys.migratedGkz] = state.migratedGkz
        preferences[Keys.deleteTokenPending] = state.deleteTokenPending
    }

    private object Keys {
        val desiredGkz = stringSetPreferencesKey("push.v2.desiredGkz")
        val enabled = booleanPreferencesKey("push.v2.enabled")
        val hasSynced = booleanPreferencesKey("push.v2.hasSynced")
        val token = stringPreferencesKey("push.v2.token")
        val subscribedGkz = stringSetPreferencesKey("push.v2.subscribedGkz")
        val legacyGkz = stringSetPreferencesKey("push.v2.legacyGkz")
        val legacyImported = booleanPreferencesKey("push.v2.legacyImported")
        val migratedGkz = stringSetPreferencesKey("push.v2.migratedGkz")
        val deleteTokenPending = booleanPreferencesKey("push.v2.deleteTokenPending")
    }
}
