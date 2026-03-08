package org.entner.HitzeV.data

import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.tasks.await
import org.entner.HitzeV.model.GeoCoordinate

class SubscriptionManager(
    private val appStorage: AppStorage,
    private val dashboardDataService: DashboardDataService,
    private val firebaseRegistrationManager: FirebaseRegistrationManager
) {
    suspend fun syncTopics(coordinates: List<GeoCoordinate>, languageCode: String): SubscriptionError? {
        val normalizedLanguageCode = normalizeLanguageCode(languageCode)
        val currentTopics = appStorage.subscribedMunicipalityIds.first()
        val storedLanguageCode = appStorage.lastSubscribedLanguageCode.first()
        val previousLanguageCode = storedLanguageCode ?: normalizedLanguageCode
        val hasStoredLanguageCode = storedLanguageCode != null
        val errors = mutableListOf<SubscriptionError>()

        if (coordinates.isEmpty()) {
            val syncErrors = synchronizeTopics(
                desiredMunicipalityIds = emptySet(),
                currentTopics = currentTopics,
                previousLanguageCode = previousLanguageCode,
                desiredLanguageCode = normalizedLanguageCode,
                hasStoredLanguageCode = hasStoredLanguageCode,
                allowUnsubscribe = true
            )
            return applyErrors(syncErrors)
        }

        val resolvedMunicipalityIds = linkedSetOf<String>()
        coordinates.forEach { coordinate ->
            try {
                resolvedMunicipalityIds += dashboardDataService.resolveMunicipalityForCoordinate(coordinate).municipalityId
            } catch (error: DashboardDataError.MunicipalityNotFound) {
                errors += SubscriptionError.MunicipalityNotFound(error.detail)
            } catch (error: DashboardDataError.Network) {
                errors += SubscriptionError.Network(error.detail)
            } catch (error: Exception) {
                errors += SubscriptionError.InvalidResponse
            }
        }

        if (resolvedMunicipalityIds.isEmpty()) {
            return applyErrors(if (errors.isEmpty()) listOf(SubscriptionError.InvalidResponse) else errors)
        }

        errors += synchronizeTopics(
            desiredMunicipalityIds = resolvedMunicipalityIds,
            currentTopics = currentTopics,
            previousLanguageCode = previousLanguageCode,
            desiredLanguageCode = normalizedLanguageCode,
            hasStoredLanguageCode = hasStoredLanguageCode,
            allowUnsubscribe = errors.isEmpty()
        )

        return applyErrors(errors)
    }

    private suspend fun synchronizeTopics(
        desiredMunicipalityIds: Set<String>,
        currentTopics: Set<String>,
        previousLanguageCode: String,
        desiredLanguageCode: String,
        hasStoredLanguageCode: Boolean,
        allowUnsubscribe: Boolean
    ): List<SubscriptionError> {
        val workingSet = currentTopics.toMutableSet()
        val errors = mutableListOf<SubscriptionError>()
        val languageChanged = previousLanguageCode != desiredLanguageCode
        val requiresTopicMigration = !hasStoredLanguageCode
        val shouldResubscribeAll = languageChanged || requiresTopicMigration
        val toSubscribe = if (shouldResubscribeAll) {
            desiredMunicipalityIds
        } else {
            desiredMunicipalityIds - workingSet
        }
        val toUnsubscribe = if (allowUnsubscribe) {
            if (shouldResubscribeAll) workingSet else (workingSet - desiredMunicipalityIds)
        } else {
            emptySet()
        }
        val shouldCleanupLegacyTopics =
            allowUnsubscribe && previousLanguageCode == desiredLanguageCode && !hasStoredLanguageCode
        val successfulTargetSubscriptions = mutableSetOf<String>()

        if (toSubscribe.isNotEmpty() || toUnsubscribe.isNotEmpty() || shouldCleanupLegacyTopics) {
            try {
                firebaseRegistrationManager.registerForPushNotificationsIfNeeded()
            } catch (error: FirebaseRegistrationError) {
                return listOf(SubscriptionError.FirebaseRegistration(error.message.orEmpty()))
            }
        }

        toSubscribe.sorted().forEach { municipalityId ->
            runCatching {
                FirebaseMessaging.getInstance()
                    .subscribeToTopic(topicName(municipalityId, desiredLanguageCode))
                    .await()
                workingSet += municipalityId
                successfulTargetSubscriptions += municipalityId
            }.onFailure { failure ->
                errors += SubscriptionError.Firebase(
                    "FCM subscribe failed for ${topicName(municipalityId, desiredLanguageCode)}: ${failure.localizedMessage}"
                )
            }
        }

        toUnsubscribe.sorted().forEach { municipalityId ->
            val shouldUnsubscribe = if (!shouldResubscribeAll) {
                true
            } else {
                municipalityId !in desiredMunicipalityIds || municipalityId in successfulTargetSubscriptions
            }

            if (!shouldUnsubscribe) {
                return@forEach
            }

            runCatching {
                FirebaseMessaging.getInstance()
                    .unsubscribeFromTopic(topicName(municipalityId, previousLanguageCode))
                    .await()
                if (municipalityId !in desiredMunicipalityIds) {
                    workingSet -= municipalityId
                }
            }.onFailure { failure ->
                errors += SubscriptionError.Firebase(
                    "FCM unsubscribe failed for ${topicName(municipalityId, previousLanguageCode)}: ${failure.localizedMessage}"
                )
            }
        }

        if (shouldCleanupLegacyTopics) {
            workingSet.sorted().forEach { municipalityId ->
                runCatching {
                    FirebaseMessaging.getInstance().unsubscribeFromTopic(legacyTopicName(municipalityId)).await()
                }.onFailure { failure ->
                    errors += SubscriptionError.Firebase(
                        "FCM legacy unsubscribe failed for ${legacyTopicName(municipalityId)}: ${failure.localizedMessage}"
                    )
                }
            }
        }

        appStorage.saveSubscribedMunicipalityIds(workingSet)
        appStorage.saveLastSubscribedLanguageCode(desiredLanguageCode)

        if (workingSet.isEmpty()) {
            runCatching { firebaseRegistrationManager.deregisterFromFirebase() }
        }

        return errors
    }

    private fun applyErrors(errors: List<SubscriptionError>): SubscriptionError? = when (errors.size) {
        0 -> null
        1 -> errors.single()
        else -> SubscriptionError.PartialSync(
            messageText = "Topic-Synchronisierung mit Teilfehlern abgeschlossen.",
            failures = errors.size
        )
    }

    private fun topicName(municipalityId: String, languageCode: String): String =
        "warngebiet_${municipalityId}_${normalizeLanguageCode(languageCode)}"

    private fun legacyTopicName(municipalityId: String): String = "warngebiet_$municipalityId"

    private fun normalizeLanguageCode(value: String): String = value.trim().lowercase().ifEmpty { "en" }
}

sealed class SubscriptionError(message: String) : Exception(message) {
    data object InvalidResponse : SubscriptionError("Ungültige Antwortstruktur von GeoSphere.")
    data class Network(val detail: String) : SubscriptionError("Netzwerkfehler: $detail")
    data class MunicipalityNotFound(val detail: String) : SubscriptionError("Gemeinde konnte nicht ermittelt werden: $detail")
    data class Firebase(val detail: String) : SubscriptionError("Firebase Messaging Fehler: $detail")
    data class FirebaseRegistration(val detail: String) : SubscriptionError("Firebase Registrierung Fehler: $detail")
    data class PartialSync(val messageText: String, val failures: Int) :
        SubscriptionError("$messageText Fehlgeschlagene Operationen: $failures.")
}
