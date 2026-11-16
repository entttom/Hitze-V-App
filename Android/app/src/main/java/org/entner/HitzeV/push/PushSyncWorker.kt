package org.entner.HitzeV.push

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import org.entner.HitzeV.appContainer
import org.entner.HitzeV.data.PushRetryScheduler
import java.util.concurrent.TimeUnit

class PushSyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val done = applicationContext.appContainer.subscriptionManager.runMaintenance()
        return when {
            done -> Result.success()
            // Devices without Play services fail forever; the next app start schedules a fresh run.
            runAttemptCount >= MAX_ATTEMPTS -> Result.failure()
            else -> Result.retry()
        }
    }

    private companion object {
        const val MAX_ATTEMPTS = 8
    }
}

class WorkManagerPushRetryScheduler(context: Context) : PushRetryScheduler {
    private val appContext = context.applicationContext

    override fun schedule(replaceExisting: Boolean) {
        val request = OneTimeWorkRequestBuilder<PushSyncWorker>()
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .build()
        // KEEP on app start: a process woken for a queued retry must not reset that retry's backoff.
        val policy = if (replaceExisting) ExistingWorkPolicy.REPLACE else ExistingWorkPolicy.KEEP
        WorkManager.getInstance(appContext).enqueueUniqueWork(UNIQUE_WORK_NAME, policy, request)
    }

    private companion object {
        const val UNIQUE_WORK_NAME = "push-topic-sync"
    }
}
