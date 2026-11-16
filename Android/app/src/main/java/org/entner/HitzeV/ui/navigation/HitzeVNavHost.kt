package org.entner.HitzeV.ui.navigation

import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.model.AddressSearchResult
import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.AppTheme
import org.entner.HitzeV.push.NotificationPermission
import org.entner.HitzeV.ui.addworkplace.AddWorkplaceActions
import org.entner.HitzeV.ui.addworkplace.AddWorkplaceScreen
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.openExternalUri
import org.entner.HitzeV.ui.dashboard.DashboardActions
import org.entner.HitzeV.ui.dashboard.DashboardScreen
import org.entner.HitzeV.ui.info.InfoScreen
import org.entner.HitzeV.ui.settings.SettingsActions
import org.entner.HitzeV.ui.settings.SettingsScreen

object Routes {
    @Serializable
    data object Dashboard

    @Serializable
    data object AddWorkplace

    @Serializable
    data object Settings

    @Serializable
    data object Info
}

/** Pops [T] only while it is on top, so a late or double back never removes the start destination. */
inline fun <reified T : Any> NavController.popIfCurrent() {
    if (currentDestination?.hasRoute<T>() == true) {
        popBackStack<T>(inclusive = true)
    }
}

@Composable
fun HitzeVNavHost(
    viewModel: DashboardViewModel,
    dashboardSnackbarHostState: SnackbarHostState,
    navController: NavHostController = rememberNavController()
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(state.highlightedMunicipalityId) {
        if (state.highlightedMunicipalityId != null && navController.currentDestination?.hasRoute<Routes.Dashboard>() == false) {
            navController.popBackStack<Routes.Dashboard>(inclusive = false)
        }
    }

    NavHost(navController = navController, startDestination = Routes.Dashboard) {
        composable<Routes.Dashboard> {
            val actions = remember(viewModel, navController) {
                object : DashboardActions {
                    override fun onAddWorkplace() {
                        viewModel.resetAddForm()
                        navController.navigate(Routes.AddWorkplace) { launchSingleTop = true }
                    }
                    override fun onOpenSettings() = navController.navigate(Routes.Settings) { launchSingleTop = true }
                    override fun onOpenInfo() = navController.navigate(Routes.Info) { launchSingleTop = true }
                    override fun onRefresh() = viewModel.refresh()
                    override fun onRetryWorksite(worksiteId: String) = viewModel.retryWorksite(worksiteId)
                    override fun onDeleteWorksite(worksiteId: String) = viewModel.deleteWorksite(worksiteId)
                    override fun onHighlightConsumed() = viewModel.onHighlightConsumed()
                }
            }
            DashboardScreen(state = state, actions = actions, snackbarHostState = dashboardSnackbarHostState)
        }

        composable<Routes.AddWorkplace> {
            val actions = remember(viewModel, navController) {
                object : AddWorkplaceActions {
                    override fun onBack() = navController.popIfCurrent<Routes.AddWorkplace>()
                    override fun onNameChanged(value: String) = viewModel.updateNameInput(value)
                    override fun onAddressChanged(value: String) = viewModel.updateAddressQuery(value)
                    override fun onSearch() = viewModel.searchAddress()
                    override fun onUseAddress(result: AddressSearchResult) = viewModel.addWorksite(result)
                    override fun onDismissError() = viewModel.dismissAddError()
                }
            }
            AddWorkplaceScreen(form = state.addForm, actions = actions)
        }

        composable<Routes.Settings> {
            val context = LocalContext.current
            val actions = remember(viewModel, navController, context) {
                object : SettingsActions {
                    override fun onBack() = navController.popIfCurrent<Routes.Settings>()
                    override fun onThemeChanged(theme: AppTheme) = viewModel.setTheme(theme)
                    override fun onLanguageChanged(language: AppLanguage) = viewModel.setLanguage(language)
                    override fun onPushEnabledChanged(enabled: Boolean) = viewModel.setPushNotificationsEnabled(enabled)
                    override fun onWorksitePushChanged(worksiteId: String, enabled: Boolean) =
                        viewModel.setWorksitePushEnabled(worksiteId, enabled)
                    override fun onOpenNotificationSettings() {
                        runCatching { context.startActivity(NotificationPermission.appNotificationSettingsIntent(context)) }
                    }
                    override fun onOpenLink(url: String) {
                        context.openExternalUri(url)
                    }
                }
            }
            SettingsScreen(state = state, actions = actions)
        }

        composable<Routes.Info> {
            val context = LocalContext.current
            val copy = LocalCopybook.current
            val snackbarHostState = remember { SnackbarHostState() }
            val scope = rememberCoroutineScope()
            InfoScreen(
                onBack = { navController.popIfCurrent<Routes.Info>() },
                onOpenUrl = { url ->
                    if (!context.openExternalUri(url) && url.startsWith("tel:")) {
                        scope.launch { snackbarHostState.showSnackbar(copy.callNotSupportedMessage) }
                    }
                },
                snackbarHostState = snackbarHostState
            )
        }
    }
}
