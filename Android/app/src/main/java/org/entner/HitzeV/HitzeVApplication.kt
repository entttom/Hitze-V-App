package org.entner.HitzeV

import android.app.Application
import org.entner.HitzeV.notifications.HeatWarningNotifications

class HitzeVApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
        HeatWarningNotifications.ensureChannel(this)
        // Re-subscribes every desired topic (restore, reinstall, token rotation) and finishes the
        // legacy-topic migration; independent of the notification permission.
        container.subscriptionManager.requestResync()
    }
}
