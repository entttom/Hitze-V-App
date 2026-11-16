package org.entner.HitzeV.ui.components

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.net.toUri

/** Returns false when nothing on the device can handle the link (e.g. tel: on Wi-Fi tablets). */
fun Context.openExternalUri(uri: String): Boolean {
    if (uri.startsWith("tel:") && !packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
        return false
    }
    val action = if (uri.startsWith("tel:")) Intent.ACTION_DIAL else Intent.ACTION_VIEW
    return try {
        startActivity(Intent(action, uri.toUri()).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (_: SecurityException) {
        false
    }
}
