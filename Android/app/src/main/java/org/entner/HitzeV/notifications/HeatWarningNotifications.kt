package org.entner.HitzeV.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.entner.HitzeV.MainActivity
import org.entner.HitzeV.R
import org.entner.HitzeV.push.EXTRA_GKZ
import org.entner.HitzeV.push.NotificationPermission
import java.time.Instant

object HeatWarningNotifications {
    const val CHANNEL_ID = "heat_warning_alerts"
    private const val WARNING_NOTIFICATION_ID = 1
    private const val LEGACY_TAG = "hitze-legacy"

    /** Also refreshes the channel's localized name and description. */
    fun ensureChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = context.getString(R.string.notification_channel_description)
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
        }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    /** Tag `hitze-<GKZ>` with a fixed id, so a newer push replaces the older one for the same municipality. */
    fun postWarning(context: Context, gkz: String, title: String, body: String, sentAt: Instant?) {
        post(context, tag = warningTag(gkz), gkz = gkz, title = title, body = body, sentAt = sentAt)
    }

    /** Same slot as the v2 warning of that GKZ, so legacy and v2 pushes replace each other. */
    fun postLegacy(context: Context, gkz: String?, title: String, body: String) {
        post(context, tag = warningTag(gkz), gkz = gkz, title = title, body = body, sentAt = null)
    }

    internal fun warningTag(gkz: String?): String = gkz?.let { "hitze-$it" } ?: LEGACY_TAG

    private fun post(context: Context, tag: String, gkz: String?, title: String, body: String, sentAt: Instant?) {
        if (!NotificationPermission.areNotificationsEnabled(context)) return
        ensureChannel(context)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_heat_warning)
            .setColor(context.getColor(R.color.notification_accent))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(contentIntent(context, gkz))
        if (sentAt != null) {
            builder.setWhen(sentAt.toEpochMilli()).setShowWhen(true)
        }

        try {
            NotificationManagerCompat.from(context).notify(tag, WARNING_NOTIFICATION_ID, builder.build())
        } catch (_: SecurityException) {
            // Permission revoked between the check and notify().
        }
    }

    private fun contentIntent(context: Context, gkz: String?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            if (gkz != null) putExtra(EXTRA_GKZ, gkz)
        }
        // Distinct request codes keep one PendingIntent (and its GKZ extra) per municipality.
        val requestCode = gkz?.let { it.toIntOrNull() ?: it.hashCode() } ?: 0
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }
}
