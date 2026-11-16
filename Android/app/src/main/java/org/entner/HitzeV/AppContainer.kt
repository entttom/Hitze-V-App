package org.entner.HitzeV

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.entner.HitzeV.data.AppStorage
import org.entner.HitzeV.data.SubscriptionManager
import org.entner.HitzeV.push.DataStorePushStateStore
import org.entner.HitzeV.push.FirebasePushMessagingClient
import org.entner.HitzeV.push.PUSH_COPY_ASSET
import org.entner.HitzeV.push.PushCopyRenderer
import org.entner.HitzeV.push.PushStateStore
import org.entner.HitzeV.push.WorkManagerPushRetryScheduler

/** Process-wide singletons, created once in [HitzeVApplication]. */
class AppContainer(context: Context) {
    private val appContext = context.applicationContext

    /** For work that must outlive a screen (e.g. finishing a push sync after the user leaves). */
    val applicationScope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val appStorage: AppStorage = AppStorage(appContext)

    val pushStateStore: PushStateStore = DataStorePushStateStore(appContext)

    val subscriptionManager: SubscriptionManager = SubscriptionManager(
        client = FirebasePushMessagingClient(),
        store = pushStateStore,
        legacySource = appStorage,
        retryScheduler = WorkManagerPushRetryScheduler(appContext)
    )

    /** Null only if the bundled push-copy.json is missing or unreadable. */
    val pushCopyRenderer: PushCopyRenderer? by lazy {
        runCatching {
            appContext.assets.open(PUSH_COPY_ASSET).bufferedReader().use { PushCopyRenderer.fromJson(it.readText()) }
        }.getOrNull()
    }
}

val Context.appContainer: AppContainer
    get() = (applicationContext as HitzeVApplication).container
