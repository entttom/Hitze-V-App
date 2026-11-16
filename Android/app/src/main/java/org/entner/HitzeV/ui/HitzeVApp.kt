package org.entner.HitzeV.ui

import android.os.Build
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.core.os.ConfigurationCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import org.entner.HitzeV.DashboardEffect
import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.push.NotificationPermission
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.copy.Copybook
import org.entner.HitzeV.ui.navigation.HitzeVNavHost
import org.entner.HitzeV.ui.navigation.Routes
import org.entner.HitzeV.ui.navigation.popIfCurrent
import org.entner.HitzeV.ui.onboarding.OnboardingScreen
import org.entner.HitzeV.ui.onboarding.hasNotificationPermission
import org.entner.HitzeV.ui.onboarding.rememberNotificationPermissionRequester
import java.util.Locale

@Composable
fun HitzeVApp(viewModel: DashboardViewModel) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val copy = remember(state.appLanguage, configuration) {
        val deviceLocale = ConfigurationCompat.getLocales(configuration)[0] ?: Locale.getDefault()
        Copybook(state.appLanguage.resolvedLanguage(deviceLocale))
    }
    var permissionGranted by remember { mutableStateOf(context.hasNotificationPermission()) }

    LifecycleResumeEffect(viewModel) {
        permissionGranted = context.hasNotificationPermission()
        viewModel.onResume(notificationsAllowed = NotificationPermission.areNotificationsEnabled(context))
        onPauseOrDispose { }
    }

    val permissionRequester = rememberNotificationPermissionRequester(
        onFinished = {
            permissionGranted = context.hasNotificationPermission()
            viewModel.onResume(notificationsAllowed = NotificationPermission.areNotificationsEnabled(context))
            if (state.hasCompletedOnboarding != true) {
                viewModel.completeOnboarding()
            }
        }
    )

    CompositionLocalProvider(LocalCopybook provides copy) {
        when (state.hasCompletedOnboarding) {
            // Splash screen stays up until preferences are loaded.
            null -> Unit
            false -> OnboardingScreen(showWelcome = true, onContinue = permissionRequester::request)
            true -> {
                val needsRestoredExplainer = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                    state.isPushEnabled &&
                    !permissionGranted &&
                    !permissionRequester.wasRequested
                if (needsRestoredExplainer) {
                    OnboardingScreen(showWelcome = false, onContinue = permissionRequester::request)
                } else {
                    MainContent(viewModel = viewModel, copy = copy)
                }
            }
        }
    }
}

@Composable
private fun MainContent(viewModel: DashboardViewModel, copy: Copybook) {
    val navController = rememberNavController()
    val snackbarHostState = remember { SnackbarHostState() }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    val currentCopy by rememberUpdatedState(copy)

    LaunchedEffect(viewModel, lifecycle) {
        lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            viewModel.effects.collect { effect ->
                when (effect) {
                    DashboardEffect.WorksiteAdded -> navController.popIfCurrent<Routes.AddWorkplace>()
                    DashboardEffect.RefreshFailed -> launch {
                        val result = snackbarHostState.showSnackbar(
                            message = currentCopy.warningsUnavailableMessage,
                            actionLabel = currentCopy.retryButton,
                            withDismissAction = true
                        )
                        if (result == SnackbarResult.ActionPerformed) {
                            viewModel.refresh()
                        }
                    }
                }
            }
        }
    }

    HitzeVNavHost(
        viewModel = viewModel,
        dashboardSnackbarHostState = snackbarHostState,
        navController = navController
    )
}
