package org.entner.HitzeV.ui.onboarding

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import java.io.File

/**
 * Remembers whether POST_NOTIFICATIONS was requested on this installation. Kept in the
 * no-backup directory on purpose: a restored setup must show the explainer once more.
 */
object NotificationPromptMarker {
    private const val FILE_NAME = "notification_permission_requested"

    fun wasRequested(context: Context): Boolean = File(context.noBackupFilesDir, FILE_NAME).exists()

    fun markRequested(context: Context) {
        runCatching { File(context.noBackupFilesDir, FILE_NAME).createNewFile() }
    }
}

fun Context.hasNotificationPermission(): Boolean =
    Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
        ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

class NotificationPermissionRequester internal constructor(
    private val launch: () -> Unit,
    private val continueWithoutPrompt: () -> Unit,
    val wasRequested: Boolean
) {
    /** Shows the system dialog on API 33+; below that there is no runtime permission. */
    fun request() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) launch() else continueWithoutPrompt()
    }
}

// The permission is only launched through request(), which checks the API level.
@SuppressLint("InlinedApi")
@Composable
fun rememberNotificationPermissionRequester(onFinished: () -> Unit): NotificationPermissionRequester {
    val context = LocalContext.current
    val currentOnFinished by rememberUpdatedState(onFinished)
    var wasRequested by remember { mutableStateOf(NotificationPromptMarker.wasRequested(context)) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        currentOnFinished()
    }
    return NotificationPermissionRequester(
        launch = {
            NotificationPromptMarker.markRequested(context)
            wasRequested = true
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        },
        continueWithoutPrompt = {
            NotificationPromptMarker.markRequested(context)
            wasRequested = true
            currentOnFinished()
        },
        wasRequested = wasRequested
    )
}
