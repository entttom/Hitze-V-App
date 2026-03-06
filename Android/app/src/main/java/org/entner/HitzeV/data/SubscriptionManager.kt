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
    suspend fun syncTopics(coordinates: List<GeoCoordinate>): SubscriptionError? {
        val currentTopics = appStorage.subscribedMunicipalityIds.first()
        val errors = mutableListOf<SubscriptionError>()

        if (coordinates.isEmpty()) {
            val syncErrors = synchronizeTopics(
                desiredMunicipalityIds = emptySet(),
                currentTopics = currentTopics,
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
            allowUnsubscribe = errors.isEmpty()
        )

        return applyErrors(errors)
    }

    private suspend fun synchronizeTopics(
        desiredMunicipalityIds: Set<String>,
        currentTopics: Set<String>,
        allowUnsubscribe: Boolean
    ): List<SubscriptionError> {
        val workingSet = currentTopics.toMutableSet()
        val errors = mutableListOf<SubscriptionError>()
        val toSubscribe = desiredMunicipalityIds - workingSet
        val toUnsubscribe = if (allowUnsubscribe) workingSet - desiredMunicipalityIds else emptySet()

        if (toSubscribe.isNotEmpty() || toUnsubscribe.isNotEmpty()) {
            try {
                firebaseRegistrationManager.registerForPushNotificationsIfNeeded()
            } catch (error: FirebaseRegistrationError) {
                return listOf(SubscriptionError.FirebaseRegistration(error.message.orEmpty()))
            }
        }

        toSubscribe.sorted().forEach { municipalityId ->
            runCatching {
                FirebaseMessaging.getInstance().subscribeToTopic(topicName(municipalityId)).await()
                workingSet += municipalityId
            }.onFailure { failure ->
                errors += SubscriptionError.Firebase("FCM subscribe failed for ${topicName(municipalityId)}: ${failure.localizedMessage}")
            }
        }

        toUnsubscribe.sorted().forEach { municipalityId ->
            runCatching {
                FirebaseMessaging.getInstance().unsubscribeFromTopic(topicName(municipalityId)).await()
                workingSet -= municipalityId
            }.onFailure { failure ->
                errors += SubscriptionError.Firebase("FCM unsubscribe failed for ${topicName(municipalityId)}: ${failure.localizedMessage}")
            }
        }

        appStorage.saveSubscribedMunicipalityIds(workingSet)

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

    private fun topicName(municipalityId: String): String = "warngebiet_$municipalityId"
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
