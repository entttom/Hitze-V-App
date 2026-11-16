package org.entner.HitzeV.push

/** [failedGkz]: requested GKZ that are not confirmed subscribed yet (they are retried in the background). */
data class PushSyncResult(val failedGkz: Set<String>, val errorMessage: String?) {
    val isSuccess: Boolean get() = failedGkz.isEmpty() && errorMessage == null
}
