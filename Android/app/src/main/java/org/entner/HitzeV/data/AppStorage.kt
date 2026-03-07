package org.entner.HitzeV.data

import android.content.Context
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStoreFile
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.AppTheme
import org.entner.HitzeV.model.Worksite
import java.io.IOException

class AppStorage(context: Context) {
    private val json = Json { ignoreUnknownKeys = true }
    private val dataStore = PreferenceDataStoreFactory.create(
        produceFile = { context.preferencesDataStoreFile("hitze_v_app.preferences_pb") }
    )

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

    val appTheme: Flow<AppTheme> = dataStore.safeData.map { preferences ->
        AppTheme.fromRawValue(preferences[Keys.theme])
    }

    val hasCompletedOnboarding: Flow<Boolean> = dataStore.safeData.map { preferences ->
        preferences[Keys.hasCompletedOnboarding] ?: false
    }

    val subscribedMunicipalityIds: Flow<Set<String>> = dataStore.safeData.map { preferences ->
        preferences[Keys.subscribedMunicipalityIds] ?: emptySet()
    }

    val customGeoSphereUrl: Flow<String> = dataStore.safeData.map { preferences ->
        preferences[Keys.customGeoSphereUrl]?.trim().orEmpty()
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

    suspend fun saveSubscribedMunicipalityIds(ids: Set<String>) {
        dataStore.edit { preferences ->
            preferences[Keys.subscribedMunicipalityIds] = ids
        }
    }

    suspend fun saveCustomGeoSphereUrl(url: String) {
        dataStore.edit { preferences ->
            preferences[Keys.customGeoSphereUrl] = url.trim()
        }
    }

    private val androidx.datastore.core.DataStore<Preferences>.safeData: Flow<Preferences>
        get() = data
            .catch { error ->
                if (error is IOException) emit(emptyPreferences()) else throw error
            }

    private object Keys {
        val worksites = stringPreferencesKey("dashboard.worksites.v1")
        val language = stringPreferencesKey("dashboard.language")
        val theme = stringPreferencesKey("app.theme")
        val hasCompletedOnboarding = booleanPreferencesKey("hasCompletedOnboarding")
        val subscribedMunicipalityIds = stringSetPreferencesKey("subscription_manager.subscribedMunicipalityIDs")
        val customGeoSphereUrl = stringPreferencesKey("network.customGeoSphereUrl")
    }
}
