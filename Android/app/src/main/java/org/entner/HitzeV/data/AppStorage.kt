package org.entner.HitzeV.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.core.handlers.ReplaceFileCorruptionHandler
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
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.AppTheme
import org.entner.HitzeV.model.Worksite
import java.io.IOException

// One DataStore per process: the delegate caches the instance, so any number of AppStorage
// wrappers share it. The name already ends in ".preferences_pb" and the delegate appends it again;
// the on-disk file of existing installs is datastore/hitze_v_app.preferences_pb.preferences_pb.
private val Context.appPreferencesDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "hitze_v_app.preferences_pb",
    corruptionHandler = ReplaceFileCorruptionHandler { emptyPreferences() }
)

class AppStorage internal constructor(private val dataStore: DataStore<Preferences>) : LegacySubscriptionSource {
    constructor(context: Context) : this(context.applicationContext.appPreferencesDataStore)

    private val json = Json { ignoreUnknownKeys = true }

    val worksites: Flow<List<Worksite>> = dataStore.safeData.map { preferences ->
        preferences[Keys.worksites]
            ?.takeIf { it.isNotBlank() }
            ?.let { encoded ->
                runCatching { json.decodeFromString<List<Worksite>>(encoded) }.getOrDefault(emptyList())
            }
            ?: emptyList()
    }

    val appLanguage: Flow<AppLanguage> = dataStore.safeData.map { preferences ->
        AppLanguage.fromRawValue(preferences[Keys.language])
    }

    /** Raw stored language ("system" or a language code); null when never set. */
    val appLanguageRawValue: Flow<String?> = dataStore.safeData.map { preferences -> preferences[Keys.language] }

    val appTheme: Flow<AppTheme> = dataStore.safeData.map { preferences ->
        AppTheme.fromRawValue(preferences[Keys.theme])
    }

    val hasCompletedOnboarding: Flow<Boolean> = dataStore.safeData.map { preferences ->
        preferences[Keys.hasCompletedOnboarding] ?: false
    }

    val isPushNotificationsEnabled: Flow<Boolean> = dataStore.safeData.map { preferences ->
        preferences[Keys.isPushNotificationsEnabled] ?: true
    }

    val disabledPushWorksiteIds: Flow<Set<String>> = dataStore.safeData.map { preferences ->
        preferences[Keys.disabledPushWorksiteIds] ?: emptySet()
    }

    @Deprecated("Pre-v2 push state; SubscriptionManager imports and clears it once.")
    val subscribedMunicipalityIds: Flow<Set<String>> = dataStore.safeData.map { preferences ->
        preferences[Keys.subscribedMunicipalityIds] ?: emptySet()
    }

    @Deprecated("Pre-v2 push state; SubscriptionManager imports and clears it once.")
    val lastSubscribedLanguageCode: Flow<String?> = dataStore.safeData.map { preferences ->
        preferences[Keys.lastSubscribedLanguageCode]?.trim()?.lowercase()?.takeIf { it.isNotEmpty() }
    }

    suspend fun saveWorksites(worksites: List<Worksite>) {
        dataStore.edit { preferences ->
            preferences[Keys.worksites] = json.encodeToString(worksites)
        }
    }

    suspend fun saveAppLanguage(language: AppLanguage) {
        dataStore.edit { preferences ->
            preferences[Keys.language] = language.rawValue
        }
    }

    suspend fun saveAppTheme(theme: AppTheme) {
        dataStore.edit { preferences ->
            preferences[Keys.theme] = theme.rawValue
        }
    }

    suspend fun saveHasCompletedOnboarding(completed: Boolean) {
        dataStore.edit { preferences ->
            preferences[Keys.hasCompletedOnboarding] = completed
        }
    }

    suspend fun savePushNotificationsEnabled(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[Keys.isPushNotificationsEnabled] = enabled
        }
    }

    suspend fun saveDisabledPushWorksiteIds(ids: Set<String>) {
        dataStore.edit { preferences ->
            preferences[Keys.disabledPushWorksiteIds] = ids
        }
    }

    @Deprecated("Pre-v2 push state; use SubscriptionManager.sync.")
    suspend fun saveSubscribedMunicipalityIds(ids: Set<String>) {
        dataStore.edit { preferences ->
            preferences[Keys.subscribedMunicipalityIds] = ids
        }
    }

    @Deprecated("Pre-v2 push state; use SubscriptionManager.sync.")
    suspend fun saveLastSubscribedLanguageCode(languageCode: String) {
        dataStore.edit { preferences ->
            preferences[Keys.lastSubscribedLanguageCode] = languageCode.trim().lowercase()
        }
    }

    override suspend fun readLegacyGkz(): Set<String> =
        dataStore.safeData.first()[Keys.subscribedMunicipalityIds].orEmpty()

    override suspend fun clearLegacyState() {
        dataStore.edit { preferences ->
            preferences.remove(Keys.subscribedMunicipalityIds)
            preferences.remove(Keys.lastSubscribedLanguageCode)
        }
    }

    private val DataStore<Preferences>.safeData: Flow<Preferences>
        get() = data
            .catch { error ->
                if (error is IOException) emit(emptyPreferences()) else throw error
            }

    private object Keys {
        val worksites = stringPreferencesKey("dashboard.worksites.v1")
        val language = stringPreferencesKey("dashboard.language")
        val theme = stringPreferencesKey("app.theme")
        val hasCompletedOnboarding = booleanPreferencesKey("hasCompletedOnboarding")
        val isPushNotificationsEnabled = booleanPreferencesKey("push.notifications.enabled")
        val disabledPushWorksiteIds = stringSetPreferencesKey("push.notifications.disabledWorksiteIds")
        val subscribedMunicipalityIds = stringSetPreferencesKey("subscription_manager.subscribedMunicipalityIDs")
        val lastSubscribedLanguageCode = stringPreferencesKey("subscription_manager.lastSubscribedLanguageCode")
    }
}
