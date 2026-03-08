package org.entner.HitzeV

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.entner.HitzeV.config.AppFeatureFlags
import org.entner.HitzeV.data.AppStorage
import org.entner.HitzeV.data.DashboardDataError
import org.entner.HitzeV.data.DashboardDataService
import org.entner.HitzeV.data.FirebaseRegistrationManager
import org.entner.HitzeV.data.NominatimSearchResult
import org.entner.HitzeV.data.NominatimSearchService
import org.entner.HitzeV.data.SubscriptionManager
import org.entner.HitzeV.model.AddressSearchResult
import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.AppTheme
import org.entner.HitzeV.model.Worksite
import org.entner.HitzeV.model.WorksiteSnapshot

class DashboardViewModel(application: Application) : AndroidViewModel(application) {
    private val appStorage = AppStorage(application)
    private val dashboardDataService = DashboardDataService(appStorage)
    private val firebaseRegistrationManager = FirebaseRegistrationManager(application)
    private val nominatimSearchService = NominatimSearchService(application)
    private val subscriptionManager = SubscriptionManager(appStorage, dashboardDataService, firebaseRegistrationManager)

    private var hasLoaded = false

    private val _uiState = kotlinx.coroutines.flow.MutableStateFlow(DashboardUiState())
    val uiState: kotlinx.coroutines.flow.MutableStateFlow<DashboardUiState> = _uiState

    init {
        observeStoredState()
    }

    fun refreshIfNeeded() {
        if (hasLoaded) return
        hasLoaded = true
        refreshAll()
    }

    fun refreshAll() {
        val worksites = _uiState.value.worksites
        val languageCode = _uiState.value.appLanguage.resolvedLanguage().code
        if (_uiState.value.isRefreshing) return

        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }

            val nextSnapshots = _uiState.value.snapshots.toMutableMap()

            worksites.forEach { worksite ->
                runCatching { dashboardDataService.fetchSnapshot(worksite.coordinate) }
                    .onSuccess { snapshot ->
                        nextSnapshots[worksite.id] = snapshot
                    }
                    .onFailure { }
            }

            subscriptionManager.syncTopics(worksites.map(Worksite::coordinate), languageCode)

            _uiState.update {
                it.copy(
                    snapshots = nextSnapshots,
                    isRefreshing = false
                )
            }
        }
    }

    fun updateNameInput(value: String) {
        _uiState.update { it.copy(nameInput = value) }
    }

    fun updateAddressQuery(value: String) {
        _uiState.update { it.copy(addressQuery = value) }
    }

    fun searchAddress() {
        performAddressSearch(_uiState.value.addressQuery)
    }

    fun addWorksite(result: AddressSearchResult, onComplete: () -> Unit = {}) {
        viewModelScope.launch {
            val currentState = _uiState.value
            val copy = currentCopy()
            val trimmedName = currentState.nameInput.trim()
            val worksite = Worksite(
                name = if (trimmedName.isNotEmpty()) trimmedName else result.title,
                address = result.subtitle,
                latitude = result.latitude,
                longitude = result.longitude
            )

            val validationError = runCatching {
                dashboardDataService.fetchSnapshot(worksite.coordinate)
            }.exceptionOrNull()

            if (validationError != null) {
                _uiState.update {
                    it.copy(
                        addressSearchMessage = when (validationError) {
                            is DashboardDataError.MunicipalityNotFound -> copy.addOutsideAustriaMessage
                            else -> copy.addressSearchFailedMessage
                        }
                    )
                }
                return@launch
            }

            val updatedWorksites = currentState.worksites + worksite
            appStorage.saveWorksites(updatedWorksites)
            _uiState.update {
                it.copy(
                    nameInput = "",
                    addressQuery = "",
                    addressResults = emptyList(),
                    addressSearchMessage = null
                )
            }
            refreshAll()
            onComplete()
        }
    }

    fun deleteWorksite(id: String) {
        viewModelScope.launch {
            val updatedWorksites = _uiState.value.worksites.filterNot { it.id == id }
            val updatedSnapshots = _uiState.value.snapshots - id
            val languageCode = _uiState.value.appLanguage.resolvedLanguage().code
            appStorage.saveWorksites(updatedWorksites)

            subscriptionManager.syncTopics(updatedWorksites.map(Worksite::coordinate), languageCode)

            _uiState.update {
                it.copy(
                    snapshots = updatedSnapshots
                )
            }
        }
    }

    fun setTheme(theme: AppTheme) {
        viewModelScope.launch {
            appStorage.saveAppTheme(theme)
        }
    }

    fun setLanguage(language: AppLanguage) {
        viewModelScope.launch {
            appStorage.saveAppLanguage(language)
            val worksites = _uiState.value.worksites
            val languageCode = language.resolvedLanguage().code
            subscriptionManager.syncTopics(worksites.map(Worksite::coordinate), languageCode)
        }
    }

    fun setCustomGeoSphereUrl(url: String) {
        viewModelScope.launch {
            appStorage.saveCustomGeoSphereUrl(url)
        }
    }

    fun completeOnboarding(skipPushRegistration: Boolean) {
        viewModelScope.launch {
            _uiState.update { it.copy(isRequestingNotifications = !skipPushRegistration) }

            if (!skipPushRegistration) {
                runCatching { firebaseRegistrationManager.registerForPushNotificationsIfNeeded() }
            }

            appStorage.saveHasCompletedOnboarding(true)
            _uiState.update { it.copy(isRequestingNotifications = false) }
        }
    }

    private fun observeStoredState() {
        viewModelScope.launch {
            combine(
                appStorage.worksites,
                appStorage.appLanguage,
                appStorage.appTheme,
                appStorage.hasCompletedOnboarding,
                appStorage.customGeoSphereUrl
            ) { worksites, appLanguage, appTheme, hasCompletedOnboarding, customGeoSphereUrl ->
                StoredState(worksites, appLanguage, appTheme, hasCompletedOnboarding, customGeoSphereUrl)
            }.collect { storedState ->
                _uiState.update {
                    it.copy(
                        worksites = storedState.worksites,
                        appLanguage = storedState.appLanguage,
                        appTheme = storedState.appTheme,
                        hasCompletedOnboarding = storedState.hasCompletedOnboarding,
                        showsCustomGeoSphereUrlSetting = AppFeatureFlags.enableCustomGeoSphereUrlSetting,
                        customGeoSphereUrl = storedState.customGeoSphereUrl
                    )
                }
            }
        }
    }

    private fun performAddressSearch(query: String) {
        viewModelScope.launch {
            val trimmedQuery = query.trim()
            val copy = currentCopy()

            if (trimmedQuery.isEmpty()) {
                _uiState.update {
                    it.copy(
                        addressResults = emptyList(),
                        addressSearchMessage = copy.enterAddressMessage,
                        isSearchingAddress = false
                    )
                }
                return@launch
            }

            _uiState.update { it.copy(isSearchingAddress = true, addressSearchMessage = null) }

            when (val searchResult = nominatimSearchService.search(trimmedQuery)) {
                is NominatimSearchResult.Success -> {
                    _uiState.update {
                        it.copy(
                            addressResults = searchResult.results,
                            addressSearchMessage = if (searchResult.results.isEmpty()) copy.noAddressFoundMessage else null,
                            isSearchingAddress = false
                        )
                    }
                }

                is NominatimSearchResult.Failure -> {
                    _uiState.update {
                        it.copy(
                            addressResults = emptyList(),
                            addressSearchMessage = searchResult.message.ifBlank { copy.addressSearchFailedMessage },
                            isSearchingAddress = false
                        )
                    }
                }
            }
        }
    }

    private fun currentCopy() = org.entner.HitzeV.ui.copy.Copybook(_uiState.value.appLanguage.resolvedLanguage())

    private data class StoredState(
        val worksites: List<Worksite>,
        val appLanguage: AppLanguage,
        val appTheme: AppTheme,
        val hasCompletedOnboarding: Boolean,
        val customGeoSphereUrl: String
    )
}

data class DashboardUiState(
    val worksites: List<Worksite> = emptyList(),
    val addressQuery: String = "",
    val nameInput: String = "",
    val addressResults: List<AddressSearchResult> = emptyList(),
    val addressSearchMessage: String? = null,
    val isSearchingAddress: Boolean = false,
    val snapshots: Map<String, WorksiteSnapshot> = emptyMap(),
    val isRefreshing: Boolean = false,
    val appLanguage: AppLanguage = AppLanguage.SYSTEM,
    val appTheme: AppTheme = AppTheme.SYSTEM,
    val hasCompletedOnboarding: Boolean = false,
    val isRequestingNotifications: Boolean = false,
    val showsCustomGeoSphereUrlSetting: Boolean = false,
    val customGeoSphereUrl: String = ""
)
