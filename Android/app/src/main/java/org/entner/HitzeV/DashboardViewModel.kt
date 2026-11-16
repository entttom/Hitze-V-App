package org.entner.HitzeV

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.entner.HitzeV.data.AppStorage
import org.entner.HitzeV.data.DashboardDataError
import org.entner.HitzeV.data.DashboardDataService
import org.entner.HitzeV.data.NominatimSearchResult
import org.entner.HitzeV.data.NominatimSearchService
import org.entner.HitzeV.model.AddressSearchResult
import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.AppTheme
import org.entner.HitzeV.model.Worksite
import org.entner.HitzeV.model.WorksiteSnapshot
import org.entner.HitzeV.model.normalizeMunicipalityId
import org.entner.HitzeV.push.PushSyncResult
import org.entner.HitzeV.ui.AppLocales
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.coroutines.cancellation.CancellationException

class DashboardViewModel(
    private val appStorage: AppStorage,
    private val pushSync: suspend (desiredGkz: Set<String>, enabled: Boolean, complete: Boolean) -> PushSyncResult,
    /** Outlives the screen, so leaving the dashboard does not cancel a running topic sync. */
    private val pushScope: CoroutineScope,
    private val dataService: DashboardDataService,
    private val nominatimService: NominatimSearchService,
    private val savedStateHandle: SavedStateHandle,
    private val currentAppLocale: () -> AppLanguage,
    private val applyAppLocale: (AppLanguage) -> Unit,
    private val clock: Clock = Clock.systemUTC()
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        DashboardUiState(
            today = viennaDate(clock.instant()),
            addForm = AddWorkplaceFormState(
                nameInput = savedStateHandle[KEY_NAME_INPUT] ?: "",
                addressQuery = savedStateHandle[KEY_ADDRESS_QUERY] ?: ""
            )
        )
    )
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    private val _effects = Channel<DashboardEffect>(Channel.BUFFERED)
    val effects: Flow<DashboardEffect> = _effects.receiveAsFlow()

    private val worksitesMutex = Mutex()
    private val syncMutex = Mutex()
    private var refreshJob: Job? = null
    private var searchJob: Job? = null
    private var addJob: Job? = null

    init {
        observeStoredState()
    }

    fun onResume(notificationsAllowed: Boolean) {
        _uiState.update { it.copy(notificationsAllowed = notificationsAllowed, today = viennaDate(clock.instant())) }
        val state = _uiState.value
        if (state.preferencesLoaded && needsRefresh(state, clock.instant())) {
            refresh()
        }
    }

    fun refresh() {
        if (refreshJob?.isActive == true) return
        refreshJob = viewModelScope.launch { performRefresh(_uiState.value.worksites) }
    }

    fun retryWorksite(worksiteId: String) {
        if (refreshJob?.isActive == true) return
        val worksite = _uiState.value.worksites.firstOrNull { it.id == worksiteId } ?: return
        refreshJob = viewModelScope.launch { performRefresh(listOf(worksite)) }
    }

    fun onNotificationOpened(municipalityId: String) {
        _uiState.update { it.copy(highlightedMunicipalityId = normalizeMunicipalityId(municipalityId)) }
        if (_uiState.value.preferencesLoaded) {
            refresh()
        }
    }

    fun onHighlightConsumed() {
        _uiState.update { it.copy(highlightedMunicipalityId = null) }
    }

    fun resetAddForm() {
        searchJob?.cancel()
        if (addJob?.isActive == true) return
        setFormInputs(name = "", address = "")
        _uiState.update { it.copy(addForm = AddWorkplaceFormState()) }
    }

    fun updateNameInput(value: String) {
        savedStateHandle[KEY_NAME_INPUT] = value
        _uiState.update { it.copy(addForm = it.addForm.copy(nameInput = value)) }
    }

    fun updateAddressQuery(value: String) {
        savedStateHandle[KEY_ADDRESS_QUERY] = value
        _uiState.update { it.copy(addForm = it.addForm.copy(addressQuery = value)) }
    }

    fun searchAddress() {
        val form = _uiState.value.addForm
        if (form.isSearching || form.isAdding) return
        val query = form.addressQuery.trim()
        if (query.isEmpty()) {
            _uiState.update {
                it.copy(addForm = it.addForm.copy(results = emptyList(), message = AddressSearchMessage.ENTER_ADDRESS))
            }
            return
        }

        _uiState.update { it.copy(addForm = it.addForm.copy(isSearching = true, message = null)) }
        val languageTag = _uiState.value.appLanguage.resolvedLanguage().localeTag
        searchJob = viewModelScope.launch {
            val result = nominatimService.search(query, languageTag)
            _uiState.update { state ->
                val nextForm = when (result) {
                    is NominatimSearchResult.Success -> state.addForm.copy(
                        results = result.results,
                        message = if (result.results.isEmpty()) AddressSearchMessage.NO_RESULTS else null,
                        isSearching = false
                    )
                    is NominatimSearchResult.Failure -> state.addForm.copy(
                        results = emptyList(),
                        message = AddressSearchMessage.SEARCH_FAILED,
                        isSearching = false
                    )
                }
                state.copy(addForm = nextForm)
            }
        }
    }

    fun addWorksite(result: AddressSearchResult) {
        if (_uiState.value.addForm.isAdding) return
        _uiState.update { it.copy(addForm = it.addForm.copy(addingResultId = result.id, addError = null)) }

        addJob = viewModelScope.launch {
            val trimmedName = _uiState.value.addForm.nameInput.trim()
            val draft = Worksite(
                name = trimmedName.ifEmpty { result.title },
                address = result.subtitle,
                latitude = result.latitude,
                longitude = result.longitude
            )

            val snapshot = try {
                dataService.fetchSnapshot(draft.coordinate)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                val addError = when (error) {
                    is DashboardDataError.MunicipalityNotFound -> AddWorksiteError.OUTSIDE_AUSTRIA
                    is DashboardDataError.Network -> AddWorksiteError.NETWORK
                    else -> AddWorksiteError.OTHER
                }
                _uiState.update { it.copy(addForm = it.addForm.copy(addingResultId = null, addError = addError)) }
                return@launch
            }

            val worksite = draft.copy(municipalityId = snapshot.municipalityId)
            _uiState.update {
                it.copy(loads = it.loads + (worksite.id to WorksiteLoad(LoadStatus.LOADED, snapshot)))
            }
            worksitesMutex.withLock {
                appStorage.saveWorksites(appStorage.worksites.first() + worksite)
            }
            setFormInputs(name = "", address = "")
            _uiState.update { it.copy(addForm = AddWorkplaceFormState()) }
            _effects.send(DashboardEffect.WorksiteAdded)
            syncPush()
        }
    }

    fun dismissAddError() {
        _uiState.update { it.copy(addForm = it.addForm.copy(addError = null)) }
    }

    fun deleteWorksite(id: String) {
        viewModelScope.launch {
            worksitesMutex.withLock {
                appStorage.saveWorksites(appStorage.worksites.first().filterNot { it.id == id })
                appStorage.saveDisabledPushWorksiteIds(appStorage.disabledPushWorksiteIds.first() - id)
            }
            _uiState.update { it.copy(loads = it.loads - id) }
            syncPush()
        }
    }

    fun setTheme(theme: AppTheme) {
        viewModelScope.launch { appStorage.saveAppTheme(theme) }
    }

    fun setLanguage(language: AppLanguage) {
        viewModelScope.launch {
            // Stored first: the push service renders notifications in this language.
            appStorage.saveAppLanguage(language)
            applyAppLocale(language)
        }
    }

    fun setPushNotificationsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            appStorage.savePushNotificationsEnabled(enabled)
            syncPush()
        }
    }

    fun setWorksitePushEnabled(worksiteId: String, enabled: Boolean) {
        viewModelScope.launch {
            worksitesMutex.withLock {
                val current = appStorage.disabledPushWorksiteIds.first()
                appStorage.saveDisabledPushWorksiteIds(if (enabled) current - worksiteId else current + worksiteId)
            }
            syncPush()
        }
    }

    fun completeOnboarding() {
        viewModelScope.launch {
            appStorage.saveHasCompletedOnboarding(true)
            syncPush()
        }
    }

    private suspend fun performRefresh(targets: List<Worksite>) {
        val now = clock.instant()
        _uiState.update { state ->
            state.copy(
                isRefreshing = true,
                today = viennaDate(now),
                loads = state.loads + targets.associate { worksite ->
                    worksite.id to WorksiteLoad(LoadStatus.LOADING, state.loads[worksite.id]?.snapshot)
                }
            )
        }

        val results = coroutineScope {
            targets.map { worksite ->
                async {
                    val snapshot = try {
                        dataService.fetchSnapshot(worksite.coordinate)
                    } catch (error: CancellationException) {
                        throw error
                    } catch (_: Exception) {
                        null
                    }
                    _uiState.update { state ->
                        val previous = state.loads[worksite.id]?.snapshot
                        val load = if (snapshot != null) {
                            WorksiteLoad(LoadStatus.LOADED, snapshot)
                        } else {
                            WorksiteLoad(LoadStatus.FAILED, previous)
                        }
                        state.copy(loads = state.loads + (worksite.id to load))
                    }
                    worksite.id to snapshot
                }
            }.awaitAll()
        }

        _uiState.update { it.copy(isRefreshing = false) }
        if (results.any { it.second == null }) {
            _effects.send(DashboardEffect.RefreshFailed)
        }

        val municipalityIds = results.mapNotNull { (id, snapshot) -> snapshot?.let { id to it.municipalityId } }.toMap()
        persistMunicipalityIds(municipalityIds)
        syncPush()
    }

    private suspend fun persistMunicipalityIds(municipalityIds: Map<String, String>) {
        if (municipalityIds.isEmpty()) return
        worksitesMutex.withLock {
            val stored = appStorage.worksites.first()
            val updated = mergeMunicipalityIds(stored, municipalityIds)
            if (updated != stored) {
                appStorage.saveWorksites(updated)
            }
        }
    }

    private fun syncPush(): Job = pushScope.launch {
        syncMutex.withLock {
            val enabled = appStorage.isPushNotificationsEnabled.first()
            val request = pushSyncRequest(appStorage.worksites.first(), appStorage.disabledPushWorksiteIds.first())
            val result = try {
                pushSync(request.knownGkz, enabled, request.complete)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                PushSyncResult(failedGkz = request.knownGkz, errorMessage = error.message ?: error.javaClass.simpleName)
            }
            _uiState.update {
                it.copy(pushSyncFailed = result.failedGkz.isNotEmpty() || result.errorMessage != null)
            }
        }
    }

    private fun observeStoredState() {
        viewModelScope.launch {
            val appearance = combine(
                appStorage.appLanguage,
                appStorage.appTheme,
                appStorage.hasCompletedOnboarding
            ) { language, theme, onboarded -> Triple(language, theme, onboarded) }

            val push = combine(
                appStorage.isPushNotificationsEnabled,
                appStorage.disabledPushWorksiteIds
            ) { enabled, disabledIds -> enabled to disabledIds }

            var isFirstEmission = true
            combine(appStorage.worksites, appearance, push) { worksites, (language, theme, onboarded), (pushEnabled, disabledIds) ->
                StoredState(worksites, language, theme, onboarded, pushEnabled, disabledIds)
            }.collect { stored ->
                _uiState.update { state ->
                    state.copy(
                        preferencesLoaded = true,
                        worksites = stored.worksites,
                        // Loads are not filtered here: the combined flows can emit an older worksite
                        // list after addWorksite() stored the new load, which dropped it and left the
                        // new card stuck on "loading". deleteWorksite() removes its load explicitly.
                        appLanguage = stored.language,
                        appTheme = stored.theme,
                        hasCompletedOnboarding = stored.hasCompletedOnboarding,
                        isPushEnabled = stored.isPushEnabled,
                        disabledPushWorksiteIds = stored.disabledPushWorksiteIds
                    )
                }
                if (isFirstEmission) {
                    isFirstEmission = false
                    reconcileAppLocale(stored.language)
                    refresh()
                }
            }
        }
    }

    private suspend fun reconcileAppLocale(stored: AppLanguage) {
        val current = currentAppLocale()
        if (current == stored) return
        if (current == AppLanguage.SYSTEM) {
            // Older installs kept the choice only in storage; below API 33 AppCompat may also
            // have lost it after process death.
            applyAppLocale(stored)
        } else {
            appStorage.saveAppLanguage(current)
        }
    }

    private fun setFormInputs(name: String, address: String) {
        savedStateHandle[KEY_NAME_INPUT] = name
        savedStateHandle[KEY_ADDRESS_QUERY] = address
    }

    private data class StoredState(
        val worksites: List<Worksite>,
        val language: AppLanguage,
        val theme: AppTheme,
        val hasCompletedOnboarding: Boolean,
        val isPushEnabled: Boolean,
        val disabledPushWorksiteIds: Set<String>
    )

    companion object {
        private const val KEY_NAME_INPUT = "addWorkplace.name"
        private const val KEY_ADDRESS_QUERY = "addWorkplace.address"
        private val REFRESH_INTERVAL: Duration = Duration.ofMinutes(10)
        val VIENNA: ZoneId = ZoneId.of("Europe/Vienna")

        fun viennaDate(instant: Instant): LocalDate = instant.atZone(VIENNA).toLocalDate()

        /** A worksite whose GKZ is not known yet makes the request incomplete instead of blocking it. */
        internal fun pushSyncRequest(worksites: List<Worksite>, disabledIds: Set<String>): PushSyncRequest {
            val pushWorksites = worksites.filter { it.id !in disabledIds }
            val known = pushWorksites.mapNotNull { worksite -> worksite.municipalityId?.takeIf { it.isNotBlank() } }
            return PushSyncRequest(knownGkz = known.toSet(), complete = known.size == pushWorksites.size)
        }

        /** Fills in the GKZ of every worksite that loaded, independently of the ones that failed. */
        internal fun mergeMunicipalityIds(stored: List<Worksite>, municipalityIds: Map<String, String>): List<Worksite> =
            stored.map { worksite ->
                municipalityIds[worksite.id]?.takeIf { it.isNotBlank() }?.let { worksite.copy(municipalityId = it) }
                    ?: worksite
            }

        internal fun needsRefresh(state: DashboardUiState, now: Instant): Boolean {
            if (state.worksites.isEmpty()) return false
            return state.worksites.any { worksite ->
                val load = state.loads[worksite.id]
                val updatedAt = load?.snapshot?.updatedAt
                load?.status != LoadStatus.LOADED ||
                    updatedAt == null ||
                    Duration.between(updatedAt, now) >= REFRESH_INTERVAL ||
                    viennaDate(updatedAt) != viennaDate(now)
            } && state.loads.values.none { it.status == LoadStatus.LOADING }
        }

        val Factory: ViewModelProvider.Factory = viewModelFactory {
            initializer {
                val application = checkNotNull(this[APPLICATION_KEY])
                val container = application.appContainer
                DashboardViewModel(
                    appStorage = container.appStorage,
                    pushSync = { desired, enabled, complete ->
                        container.subscriptionManager.sync(desired, enabled, complete)
                    },
                    pushScope = container.applicationScope,
                    dataService = DashboardDataService(),
                    nominatimService = NominatimSearchService(),
                    savedStateHandle = createSavedStateHandle(),
                    currentAppLocale = AppLocales::current,
                    applyAppLocale = AppLocales::apply
                )
            }
        }
    }
}

internal data class PushSyncRequest(val knownGkz: Set<String>, val complete: Boolean)

enum class LoadStatus { LOADING, LOADED, FAILED }

data class WorksiteLoad(
    val status: LoadStatus,
    val snapshot: WorksiteSnapshot? = null
)

enum class AddressSearchMessage { ENTER_ADDRESS, NO_RESULTS, SEARCH_FAILED }

enum class AddWorksiteError { OUTSIDE_AUSTRIA, NETWORK, OTHER }

data class AddWorkplaceFormState(
    val nameInput: String = "",
    val addressQuery: String = "",
    val results: List<AddressSearchResult> = emptyList(),
    val message: AddressSearchMessage? = null,
    val isSearching: Boolean = false,
    val addingResultId: String? = null,
    val addError: AddWorksiteError? = null
) {
    val isAdding: Boolean get() = addingResultId != null
    val canSearch: Boolean get() = addressQuery.isNotBlank() && !isSearching && !isAdding
}

data class DashboardUiState(
    val preferencesLoaded: Boolean = false,
    val worksites: List<Worksite> = emptyList(),
    val loads: Map<String, WorksiteLoad> = emptyMap(),
    val isRefreshing: Boolean = false,
    val today: LocalDate = LocalDate.now(DashboardViewModel.VIENNA),
    val appLanguage: AppLanguage = AppLanguage.SYSTEM,
    val appTheme: AppTheme = AppTheme.SYSTEM,
    val hasCompletedOnboarding: Boolean? = null,
    val isPushEnabled: Boolean = true,
    val disabledPushWorksiteIds: Set<String> = emptySet(),
    val notificationsAllowed: Boolean = true,
    val pushSyncFailed: Boolean = false,
    val highlightedMunicipalityId: String? = null,
    val addForm: AddWorkplaceFormState = AddWorkplaceFormState()
)

sealed interface DashboardEffect {
    data object WorksiteAdded : DashboardEffect
    data object RefreshFailed : DashboardEffect
}
