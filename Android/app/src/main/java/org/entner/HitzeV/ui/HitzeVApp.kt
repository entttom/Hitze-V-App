@file:OptIn(ExperimentalMaterial3Api::class)

package org.entner.HitzeV.ui

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AddCircle
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.ReportProblem
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Thermostat
import androidx.compose.material.icons.rounded.Verified
import androidx.compose.material.icons.rounded.WarningAmber
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.delay
import org.entner.HitzeV.DashboardUiState
import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.R
import org.entner.HitzeV.model.AddressSearchResult
import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.AppTheme
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.Worksite
import org.entner.HitzeV.model.WorksiteSnapshot
import org.entner.HitzeV.ui.copy.Copybook
import org.entner.HitzeV.ui.theme.AlertOrange
import org.entner.HitzeV.ui.theme.AlertRed
import org.entner.HitzeV.ui.theme.AlertYellow
import org.entner.HitzeV.ui.theme.CalmGreen
import org.entner.HitzeV.ui.theme.ColorWhite
import org.entner.HitzeV.ui.theme.GoldenSun
import org.entner.HitzeV.ui.theme.HitzeVTheme
import org.entner.HitzeV.ui.theme.SandBackground
import org.entner.HitzeV.ui.theme.SkyBlue
import org.entner.HitzeV.ui.theme.SoftBorder
import org.entner.HitzeV.ui.theme.SurfaceLight
import java.time.LocalDate
import java.util.Calendar

private object Routes {
    const val Dashboard = "dashboard"
    const val AddWorkplace = "addWorkplace"
    const val Settings = "settings"
    const val Info = "info"
}

@Composable
fun HitzeVApp(viewModel: DashboardViewModel = viewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val copy = remember(uiState.appLanguage) { Copybook(uiState.appLanguage.resolvedLanguage()) }
    val darkTheme = when (uiState.appTheme) {
        AppTheme.SYSTEM -> androidx.compose.foundation.isSystemInDarkTheme()
        AppTheme.LIGHT -> false
        AppTheme.DARK -> true
    }
    val navController = rememberNavController()
    var showLaunchOverlay by rememberSaveable { mutableStateOf(true) }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        viewModel.completeOnboarding(skipPushRegistration = !granted)
    }

    LaunchedEffect(Unit) {
        delay(2_400)
        showLaunchOverlay = false
    }

    HitzeVTheme(darkTheme = darkTheme) {
        Box(modifier = Modifier.fillMaxSize()) {
            if (!uiState.hasCompletedOnboarding) {
                OnboardingScreen(
                    copy = copy,
                    isRequesting = uiState.isRequestingNotifications,
                    onAllow = {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        } else {
                            viewModel.completeOnboarding(skipPushRegistration = false)
                        }
                    },
                    onSkip = { viewModel.completeOnboarding(skipPushRegistration = true) }
                )
            } else {
                AppNavHost(
                    navController = navController,
                    uiState = uiState,
                    copy = copy,
                    viewModel = viewModel
                )
            }

            AnimatedVisibility(
                visible = showLaunchOverlay,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                LaunchOverlay(copy = copy)
            }
        }
    }
}

@Composable
private fun AppNavHost(
    navController: NavHostController,
    uiState: DashboardUiState,
    copy: Copybook,
    viewModel: DashboardViewModel
) {
    NavHost(
        navController = navController,
        startDestination = Routes.Dashboard
    ) {
        composable(Routes.Dashboard) {
            DashboardScreen(
                uiState = uiState,
                copy = copy,
                onAddWorkplace = { navController.navigate(Routes.AddWorkplace) },
                onSettings = { navController.navigate(Routes.Settings) },
                onInfo = { navController.navigate(Routes.Info) },
                onRefresh = viewModel::refreshAll,
                onDeleteWorksite = viewModel::deleteWorksite,
                onRefreshIfNeeded = viewModel::refreshIfNeeded
            )
        }
        composable(Routes.AddWorkplace) {
            AddWorkplaceScreen(
                uiState = uiState,
                copy = copy,
                onClose = { navController.popBackStack() },
                onNameChanged = viewModel::updateNameInput,
                onAddressChanged = viewModel::updateAddressQuery,
                onSearch = viewModel::searchAddress,
                onUseAddress = { result ->
                    viewModel.addWorksite(result) {
                        navController.popBackStack()
                    }
                }
            )
        }
        composable(Routes.Settings) {
            SettingsScreen(
                uiState = uiState,
                copy = copy,
                onClose = { navController.popBackStack() },
                onThemeChanged = viewModel::setTheme,
                onLanguageChanged = viewModel::setLanguage
            )
        }
        composable(Routes.Info) {
            InfoScreen(copy = copy, onClose = { navController.popBackStack() })
        }
    }
}

@Composable
private fun DashboardScreen(
    uiState: DashboardUiState,
    copy: Copybook,
    onAddWorkplace: () -> Unit,
    onSettings: () -> Unit,
    onInfo: () -> Unit,
    onRefresh: () -> Unit,
    onDeleteWorksite: (String) -> Unit,
    onRefreshIfNeeded: () -> Unit
) {
    val snapshots = uiState.worksites.mapNotNull { uiState.snapshots[it.id] }
    val highestSeverity = snapshots.maxByOrNull { it.severity.level }?.severity ?: HazardSeverity.NONE
    val highestUv = snapshots.maxOfOrNull { it.uvIndex ?: Double.MIN_VALUE }?.takeUnless { it == Double.MIN_VALUE }
    val maxApparentTemperature = snapshots.maxOfOrNull { it.apparentTemperature ?: Double.MIN_VALUE }?.takeUnless { it == Double.MIN_VALUE }
    val activeWarningCount = snapshots.count { it.severity != HazardSeverity.NONE }
    val currentYear = Calendar.getInstance().get(Calendar.YEAR)

    LaunchedEffect(Unit) {
        onRefreshIfNeeded()
    }

    Scaffold(
        containerColor = Color.Transparent,
        contentWindowInsets = WindowInsets(0.dp),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        copy.shortTitle,
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                navigationIcon = {
                    ToolbarCircleButton(icon = Icons.Rounded.Info, description = copy.infoButtonLabel, onClick = onInfo)
                },
                actions = {
                    ToolbarCircleButton(icon = Icons.Rounded.Settings, description = copy.settingsTitle, onClick = onSettings)
                    Spacer(modifier = Modifier.width(6.dp))
                    ToolbarCircleButton(icon = Icons.Rounded.AddCircle, description = copy.addWorkplaceTitle, onClick = onAddWorkplace)
                }
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.fillMaxSize()) {
            AtmosphereBackground()

            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(start = 16.dp, top = 12.dp, end = 16.dp, bottom = 32.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    HeroCard(
                        copy = copy,
                        worksitesCount = uiState.worksites.size,
                        warningCount = activeWarningCount,
                        highestSeverity = highestSeverity,
                        statusMessage = uiState.statusMessage,
                        onRefresh = onRefresh
                    )
                }
                item {
                    GlanceCard(
                        copy = copy,
                        highestSeverity = highestSeverity,
                        highestUv = highestUv,
                        maxApparentTemperature = maxApparentTemperature
                    )
                }
                item {
                    WorksitesCard(
                        copy = copy,
                        worksites = uiState.worksites,
                        snapshots = uiState.snapshots,
                        onDeleteWorksite = onDeleteWorksite
                    )
                }
                item {
                    LegalFooter(copy = copy, currentYear = currentYear)
                }
            }
        }
    }
}

@Composable
private fun HeroCard(
    copy: Copybook,
    worksitesCount: Int,
    warningCount: Int,
    highestSeverity: HazardSeverity,
    statusMessage: String?,
    onRefresh: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(
                        Color(0xFFF96F42),
                        Color(0xFFF7AD3B),
                        Color(0xFF3EADE0)
                    )
                )
            )
            .padding(20.dp)
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .offset(x = 32.dp, y = (-32).dp)
                .size(120.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.06f))
        )

        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(
                text = copy.dashboardTitle,
                style = MaterialTheme.typography.displayMedium,
                color = ColorWhite,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )

            Text(
                text = copy.dashboardSubtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = ColorWhite.copy(alpha = 0.88f),
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )

            Text(
                text = copy.severityAction(highestSeverity),
                style = MaterialTheme.typography.bodyMedium,
                color = ColorWhite,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                HeroMetricBubble(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Rounded.LocationOn,
                    label = copy.workplaceLabel,
                    value = worksitesCount.toString(),
                    tint = CalmGreen
                )
                HeroMetricBubble(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Rounded.WarningAmber,
                    label = copy.warningsLabel,
                    value = warningCount.toString(),
                    tint = AlertOrange
                )
            }

            if (!statusMessage.isNullOrBlank()) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Color.Black.copy(alpha = 0.16f)
                ) {
                    Text(
                        text = statusMessage,
                        color = ColorWhite,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp)
                    )
                }
            }

            Surface(
                onClick = onRefresh,
                shape = RoundedCornerShape(999.dp),
                color = ColorWhite.copy(alpha = 0.18f)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Rounded.Refresh, contentDescription = null, tint = ColorWhite, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(copy.refreshButton, color = ColorWhite, style = MaterialTheme.typography.labelLarge)
                }
            }
        }
    }
}

@Composable
private fun HeroMetricBubble(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    label: String,
    value: String,
    tint: Color
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        color = tint.copy(alpha = 0.32f)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, contentDescription = null, tint = ColorWhite, modifier = Modifier.size(14.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(label, color = ColorWhite.copy(alpha = 0.92f), style = MaterialTheme.typography.labelSmall)
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(value, color = ColorWhite, style = MaterialTheme.typography.titleLarge)
        }
    }
}

@Composable
private fun GlanceCard(
    copy: Copybook,
    highestSeverity: HazardSeverity,
    highestUv: Double?,
    maxApparentTemperature: Double?
) {
    FrostedCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionEyebrow(text = copy.glanceTitle)
            Column {
                Text(copy.glanceTitle, style = MaterialTheme.typography.titleLarge)
                Text(copy.glanceSubtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                GlanceTile(
                    modifier = Modifier.weight(1f),
                    title = copy.currentRiskTitle,
                    value = copy.severityHeadline(highestSeverity),
                    icon = severityIcon(highestSeverity),
                    tint = severityColor(highestSeverity)
                )
                GlanceTile(
                    modifier = Modifier.weight(1f),
                    title = copy.uvPeakTitle,
                    value = highestUv?.let { "UV %.1f".format(it) } ?: copy.notAvailableShort,
                    icon = Icons.Rounded.WarningAmber,
                    tint = GoldenSun
                )
                GlanceTile(
                    modifier = Modifier.weight(1f),
                    title = copy.apparentTitle,
                    value = maxApparentTemperature?.let { "%.1f C".format(it) } ?: copy.notAvailableShort,
                    icon = Icons.Rounded.Thermostat,
                    tint = AlertRed
                )
            }
        }
    }
}

@Composable
private fun GlanceTile(
    modifier: Modifier = Modifier,
    title: String,
    value: String,
    icon: ImageVector,
    tint: Color
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.66f)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(18.dp))
            Text(value, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, maxLines = 2)
            Text(title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f))
        }
    }
}

@Composable
private fun WorksitesCard(
    copy: Copybook,
    worksites: List<Worksite>,
    snapshots: Map<String, WorksiteSnapshot>,
    onDeleteWorksite: (String) -> Unit
) {
    FrostedCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionEyebrow(text = copy.monitoredWorkplacesTitle)
            Text(copy.monitoredWorkplacesTitle, style = MaterialTheme.typography.titleLarge)

            if (worksites.isEmpty()) {
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)
                ) {
                    Text(
                        text = copy.noWorkplaces,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp)
                    )
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    worksites.forEach { worksite ->
                        WorksiteCard(
                            copy = copy,
                            worksite = worksite,
                            snapshot = snapshots[worksite.id],
                            onDelete = { onDeleteWorksite(worksite.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun LegalFooter(copy: Copybook, currentYear: Int) {
    val uriHandler = LocalUriHandler.current

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = copy.copyrightLine(currentYear),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
            textAlign = TextAlign.Center
        )
        TextButton(onClick = { uriHandler.openUri(copy.legalLinkURL) }) {
            Text(copy.legalLinkLabel)
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun WorksiteCard(
    copy: Copybook,
    worksite: Worksite,
    snapshot: WorksiteSnapshot?,
    onDelete: () -> Unit
) {
    var showDeleteConfirmation by remember { mutableStateOf(false) }
    var isPressed by remember { mutableStateOf(false) }
    val severity = snapshot?.severity ?: HazardSeverity.NONE
    val isActive = showDeleteConfirmation || isPressed
    val scale by animateFloatAsState(if (isActive) 0.985f else 1f, label = "worksiteScale")
    val borderColor = if (isActive) AlertRed.copy(alpha = 0.85f) else Color.Black.copy(alpha = 0.06f)
    val cardShape = RoundedCornerShape(18.dp)

    if (showDeleteConfirmation) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirmation = false },
            title = { Text(copy.deleteWorkplace) },
            text = { Text(copy.deleteWorkplaceMessage(worksite.name)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirmation = false
                        onDelete()
                    }
                ) {
                    Text(copy.deleteWorkplace, color = AlertRed)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirmation = false }) {
                    Text(copy.cancelButton)
                }
            }
        )
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .scale(scale)
            .pointerInput(worksite.id) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    },
                    onLongPress = {
                        showDeleteConfirmation = true
                    }
                )
            }
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(if (isActive) 16.dp else 8.dp, cardShape, ambientColor = if (isActive) AlertRed.copy(alpha = 0.22f) else Color.Black.copy(alpha = 0.08f), spotColor = if (isActive) AlertRed.copy(alpha = 0.22f) else Color.Black.copy(alpha = 0.08f))
                .clip(cardShape)
                .background(
                    if (severity == HazardSeverity.NONE) {
                        Brush.linearGradient(
                            listOf(
                                MaterialTheme.colorScheme.surface.copy(alpha = 0.94f),
                                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.78f)
                            )
                        )
                    } else {
                        Brush.linearGradient(
                            listOf(
                                severityColor(severity).copy(alpha = 0.96f),
                                severityColor(severity).copy(alpha = 0.82f)
                            )
                        )
                    }
                )
                .border(1.dp, borderColor, cardShape)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (severity != HazardSeverity.NONE) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(CircleShape)
                                .background(ColorWhite.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                severityIcon(severity),
                                contentDescription = null,
                                tint = ColorWhite,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }

                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(verticalAlignment = Alignment.Top) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    worksite.name,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = worksiteTitleColor(severity)
                                )
                                if (!worksite.address.isNullOrBlank()) {
                                    Text(
                                        text = worksite.address,
                                        style = MaterialTheme.typography.labelLarge,
                                        color = worksiteDetailColor(severity),
                                        maxLines = 2,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }

                            if (snapshot != null) {
                                Column(horizontalAlignment = Alignment.End) {
                                    MiniFact(Icons.Rounded.WarningAmber, snapshot.uvIndex?.let { "UV %.1f".format(it) } ?: "UV ${copy.notAvailableShort}", worksiteDetailColor(severity))
                                    MiniFact(Icons.Rounded.Thermostat, snapshot.apparentTemperature?.let { "%.1f C".format(it) } ?: copy.notAvailableShort, worksiteDetailColor(severity))
                                }
                            }
                        }

                        if (snapshot == null) {
                            Text(copy.loading, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
                        } else {
                            Text(snapshot.municipalityName, style = MaterialTheme.typography.labelLarge, color = worksiteDetailColor(severity))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.Center
                            ) {
                                snapshot.forecasts.forEach { forecast ->
                                    Box(modifier = Modifier.padding(horizontal = 4.dp)) {
                                        DailyForecastChip(copy = copy, forecastDate = forecast.date, severity = forecast.severity, temperature = forecast.apparentTemperatureMax)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (isActive) {
                Box(
                    modifier = Modifier
                        .matchParentSize()
                        .background(
                            Brush.linearGradient(
                                listOf(AlertRed.copy(alpha = 0.06f), AlertRed.copy(alpha = 0.24f))
                            )
                        )
                )
            }
        }

        AnimatedVisibility(
            visible = isActive,
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(10.dp),
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut()
        ) {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = AlertRed
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(Icons.Rounded.Delete, contentDescription = null, tint = ColorWhite, modifier = Modifier.size(14.dp))
                    Column {
                        Text(copy.deleteWorkplace, color = ColorWhite, style = MaterialTheme.typography.labelSmall)
                        Text(worksite.name, color = ColorWhite, style = MaterialTheme.typography.labelLarge, maxLines = 1)
                    }
                }
            }
        }
    }
}

@Composable
private fun MiniFact(icon: ImageVector, text: String, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(14.dp))
        Text(text, color = color, style = MaterialTheme.typography.labelSmall)
    }
}

@Composable
private fun DailyForecastChip(
    copy: Copybook,
    forecastDate: LocalDate,
    severity: HazardSeverity,
    temperature: Double?
) {
    val background = if (severity == HazardSeverity.NONE) {
        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
    } else {
        severityColor(severity)
    }
    val foreground = if (severity == HazardSeverity.NONE) MaterialTheme.colorScheme.onSurface else ColorWhite

    Surface(
        shape = RoundedCornerShape(12.dp),
        color = background
    ) {
        Column(
            modifier = Modifier
                .width(44.dp)
                .padding(vertical = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(copy.todayTitle(forecastDate), style = MaterialTheme.typography.labelSmall, color = foreground)
            if (severity != HazardSeverity.NONE) {
                Icon(severityIcon(severity), contentDescription = null, tint = foreground, modifier = Modifier.size(14.dp))
            }
            Text(
                temperature?.let { "%.0f°".format(it) } ?: "-",
                style = MaterialTheme.typography.labelLarge,
                color = foreground
            )
        }
    }
}

@Composable
private fun AddWorkplaceScreen(
    uiState: DashboardUiState,
    copy: Copybook,
    onClose: () -> Unit,
    onNameChanged: (String) -> Unit,
    onAddressChanged: (String) -> Unit,
    onSearch: () -> Unit,
    onUseAddress: (AddressSearchResult) -> Unit
) {
    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text(copy.addWorkplaceTitle) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                navigationIcon = {
                    TextButton(onClick = onClose) {
                        Text(copy.cancelButton)
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.fillMaxSize()) {
            AtmosphereBackground()

            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                item {
                    HeroSheetCard(
                        title = copy.addWorkplaceTitle,
                        body = copy.t(
                            "Lege einen Namen fest und suche danach nach einer Adresse in Österreich.",
                            "Set a label and then search for an address in Austria."
                        )
                    )
                }

                item {
                    FrostedCard {
                        Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
                            InputSection(
                                label = copy.namePlaceholder,
                                value = uiState.nameInput,
                                placeholder = copy.t("Optional", "Optional"),
                                onValueChange = onNameChanged
                            )

                            InputSection(
                                label = copy.addressPlaceholder,
                                value = uiState.addressQuery,
                                placeholder = copy.addressFieldHint,
                                onValueChange = onAddressChanged,
                                imeAction = ImeAction.Search,
                                keyboardActions = KeyboardActions(onSearch = { onSearch() }),
                                leadingIcon = {
                                    Icon(Icons.Rounded.Search, contentDescription = null)
                                }
                            )

                            GradientActionButton(
                                text = copy.searchAddressButton,
                                enabled = uiState.addressQuery.isNotBlank() && !uiState.isSearchingAddress,
                                loading = uiState.isSearchingAddress,
                                icon = Icons.Rounded.Search,
                                onClick = onSearch
                            )
                        }
                    }
                }

                if (!uiState.addressSearchMessage.isNullOrBlank()) {
                    item {
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = MaterialTheme.colorScheme.surface.copy(alpha = 0.74f)
                        ) {
                            Text(
                                text = uiState.addressSearchMessage,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                                modifier = Modifier.padding(14.dp)
                            )
                        }
                    }
                }

                if (uiState.addressResults.isNotEmpty()) {
                    item {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            SectionEyebrow(text = copy.searchResultsTitle)
                            Text(copy.searchResultsTitle, style = MaterialTheme.typography.titleLarge)
                        }
                    }

                    items(uiState.addressResults, key = { it.id }) { result ->
                        AddressResultCard(copy = copy, result = result, onUseAddress = { onUseAddress(result) })
                    }
                }
            }
        }
    }
}

@Composable
private fun InputSection(
    label: String,
    value: String,
    placeholder: String,
    onValueChange: (String) -> Unit,
    imeAction: ImeAction = ImeAction.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    leadingIcon: @Composable (() -> Unit)? = null
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(label, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
        Surface(
            shape = RoundedCornerShape(16.dp),
            color = SurfaceLight.copy(alpha = 0.9f),
            shadowElevation = 3.dp
        ) {
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = leadingIcon,
                trailingIcon = if (value.isNotBlank()) {
                    {
                        IconButton(onClick = { onValueChange("") }) {
                            Icon(Icons.Rounded.Close, contentDescription = null, modifier = Modifier.size(18.dp))
                        }
                    }
                } else {
                    null
                },
                placeholder = { Text(placeholder) },
                shape = RoundedCornerShape(16.dp),
                keyboardOptions = KeyboardOptions(imeAction = imeAction),
                keyboardActions = keyboardActions,
                singleLine = true
            )
        }
    }
}

@Composable
private fun AddressResultCard(
    copy: Copybook,
    result: AddressSearchResult,
    onUseAddress: () -> Unit
) {
    FrostedCard {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(SkyBlue.copy(alpha = 0.14f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Rounded.LocationOn, contentDescription = null, tint = SkyBlue)
            }
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(result.title, style = MaterialTheme.typography.titleMedium)
                Text(result.subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
            }
            Surface(onClick = onUseAddress, shape = CircleShape, color = SkyBlue) {
                Text(
                    copy.useAddressButton,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    color = ColorWhite,
                    style = MaterialTheme.typography.labelLarge
                )
            }
        }
    }
}

@Composable
private fun SettingsScreen(
    uiState: DashboardUiState,
    copy: Copybook,
    onClose: () -> Unit,
    onThemeChanged: (AppTheme) -> Unit,
    onLanguageChanged: (AppLanguage) -> Unit
) {
    val uriHandler = LocalUriHandler.current

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(copy.settingsTitle, textAlign = TextAlign.Center)
                    }
                },
                navigationIcon = {
                    TextButton(onClick = onClose) {
                        Text(copy.settingsCloseButton)
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            HeroSheetCard(
                title = copy.settingsTitle,
                body = copy.t(
                    "Passe Darstellung, Sprache und rechtliche Hinweise an.",
                    "Adjust appearance, language, and legal details."
                )
            )

            SectionCard(title = copy.appearanceSection) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ThemeOptionButton(
                        modifier = Modifier.weight(1f),
                        selected = uiState.appTheme == AppTheme.SYSTEM,
                        label = copy.themeSystem,
                        onClick = { onThemeChanged(AppTheme.SYSTEM) }
                    )
                    ThemeOptionButton(
                        modifier = Modifier.weight(1f),
                        selected = uiState.appTheme == AppTheme.LIGHT,
                        label = copy.themeLight,
                        onClick = { onThemeChanged(AppTheme.LIGHT) }
                    )
                    ThemeOptionButton(
                        modifier = Modifier.weight(1f),
                        selected = uiState.appTheme == AppTheme.DARK,
                        label = copy.themeDark,
                        onClick = { onThemeChanged(AppTheme.DARK) }
                    )
                }
            }

            SectionCard(title = copy.languageSection) {
                AppLanguage.entries.forEach { language ->
                    ThemeOptionButton(
                        modifier = Modifier.fillMaxWidth(),
                        selected = uiState.appLanguage == language,
                        label = copy.languageOption(language),
                        onClick = { onLanguageChanged(language) }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            SectionCard(title = copy.aboutSection) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Text(copy.dataSourceLine, style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(copy.geocodingAttributionLine, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(copy.copyrightLine(Calendar.getInstance().get(Calendar.YEAR)), textAlign = TextAlign.Center)
                    Spacer(modifier = Modifier.height(6.dp))
                    TextButton(onClick = { uriHandler.openUri(copy.legalLinkURL) }) {
                        Text(copy.legalLinkLabel)
                    }
                }
            }
        }
    }
}

@Composable
private fun ThemeOptionButton(
    modifier: Modifier = Modifier,
    selected: Boolean,
    label: String,
    onClick: () -> Unit
) {
    Surface(
        modifier = modifier,
        onClick = onClick,
        shape = RoundedCornerShape(16.dp),
        color = if (selected) WarmGradientStart else MaterialTheme.colorScheme.surface,
        tonalElevation = if (selected) 0.dp else 2.dp
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            textAlign = TextAlign.Center,
            color = if (selected) ColorWhite else MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun SectionCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    FrostedCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp), content = {
            Text(title, style = MaterialTheme.typography.titleMedium)
            content()
        })
    }
}

@Composable
private fun InfoScreen(copy: Copybook, onClose: () -> Unit) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(copy.infoScreenTitle) },
                navigationIcon = {
                    TextButton(onClick = onClose) {
                        Text(copy.settingsCloseButton)
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                HeroSheetCard(title = copy.infoScreenHeatMeasuresTitle, body = copy.infoScreenHeatMeasuresSubtitle)
            }
            item {
                InfoCard(level = "2", tint = AlertYellow, title = copy.infoScreenLevel2Title, body = copy.infoScreenLevel2Body)
            }
            item {
                InfoCard(level = "3", tint = AlertOrange, title = copy.infoScreenLevel3Title, body = copy.infoScreenLevel3Body)
            }
            item {
                InfoCard(level = "4", tint = AlertRed, title = copy.infoScreenLevel4Title, body = copy.infoScreenLevel4Body)
            }
        }
    }
}

@Composable
private fun InfoCard(level: String, tint: Color, title: String, body: String) {
    FrostedCard {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Box(
                    modifier = Modifier
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(tint),
                    contentAlignment = Alignment.Center
                ) {
                    Text(level, color = ColorWhite, style = MaterialTheme.typography.labelLarge)
                }
                Text(title, style = MaterialTheme.typography.titleMedium, color = tint)
            }
            Text(body, style = MaterialTheme.typography.bodyLarge)
        }
    }
}

@Composable
private fun OnboardingScreen(
    copy: Copybook,
    isRequesting: Boolean,
    onAllow: () -> Unit,
    onSkip: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        Color(0xFFF96F42),
                        Color(0xFFF7AD3B),
                        Color(0xFF3EADE0)
                    )
                )
            )
            .statusBarsPadding()
            .navigationBarsPadding()
            .padding(horizontal = 24.dp, vertical = 32.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(1.dp))
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Rounded.WarningAmber,
                    contentDescription = null,
                    tint = ColorWhite,
                    modifier = Modifier.size(88.dp)
                )
                Spacer(modifier = Modifier.height(24.dp))
                Text(copy.onboardingWelcomeTitle, style = MaterialTheme.typography.displayMedium, color = ColorWhite, textAlign = TextAlign.Center)
                Spacer(modifier = Modifier.height(16.dp))
                Text(copy.onboardingWelcomeText, style = MaterialTheme.typography.bodyLarge, color = ColorWhite.copy(alpha = 0.92f), textAlign = TextAlign.Center)
            }

            Surface(
                shape = RoundedCornerShape(24.dp),
                color = Color.Black.copy(alpha = 0.18f)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(Icons.Rounded.Info, contentDescription = null, tint = ColorWhite, modifier = Modifier.size(40.dp))
                    Text(copy.onboardingPushTitle, style = MaterialTheme.typography.titleLarge, color = ColorWhite)
                    Text(copy.onboardingPushText, style = MaterialTheme.typography.bodyMedium, color = ColorWhite.copy(alpha = 0.9f), textAlign = TextAlign.Center)
                }
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Button(
                    onClick = onAllow,
                    enabled = !isRequesting,
                    modifier = Modifier.fillMaxWidth(),
                    shape = CircleShape,
                    contentPadding = PaddingValues(vertical = 16.dp)
                ) {
                    if (isRequesting) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            strokeWidth = 2.dp,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    Text(copy.onboardingAllowButton)
                }
                Spacer(modifier = Modifier.height(12.dp))
                TextButton(onClick = onSkip, enabled = !isRequesting) {
                    Text(copy.onboardingSkipButton, color = ColorWhite.copy(alpha = 0.84f))
                }
            }
        }
    }
}

@Composable
private fun LaunchOverlay(copy: Copybook) {
    var contentVisible by remember { mutableStateOf(false) }
    val infiniteTransition = rememberInfiniteTransition(label = "launchTransition")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.15f,
        animationSpec = infiniteRepeatable(animation = tween(durationMillis = 2000)),
        label = "launchPulse"
    )
    val circleOpacity by infiniteTransition.animateFloat(
        initialValue = 0.35f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(animation = tween(durationMillis = 800)),
        label = "launchOpacity"
    )
    val contentScale by animateFloatAsState(targetValue = if (contentVisible) 1f else 0.94f, animationSpec = tween(800), label = "launchContentScale")
    val contentOpacity by animateFloatAsState(targetValue = if (contentVisible) 1f else 0.35f, animationSpec = tween(800), label = "launchContentOpacity")

    LaunchedEffect(Unit) {
        contentVisible = true
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(SandBackground)
    ) {
        Box(
            modifier = Modifier
                .size(220.dp)
                .offset(x = 180.dp, y = (-180).dp)
                .scale(scale)
                .clip(CircleShape)
                .background(GoldenSun.copy(alpha = 0.18f * circleOpacity))
                .align(Alignment.TopEnd)
        )
        Box(
            modifier = Modifier
                .size(260.dp)
                .offset(x = (-170).dp, y = 260.dp)
                .scale(scale)
                .clip(CircleShape)
                .background(SkyBlue.copy(alpha = 0.14f * circleOpacity))
                .align(Alignment.BottomStart)
        )
        Column(
            modifier = Modifier
                .align(Alignment.Center)
                .scale(contentScale),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Image(
                painter = painterResource(id = R.drawable.launch_logo),
                contentDescription = null,
                modifier = Modifier.size(92.dp),
                contentScale = ContentScale.Fit
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(copy.shortTitle, style = MaterialTheme.typography.displayMedium, color = MaterialTheme.colorScheme.onBackground.copy(alpha = contentOpacity))
            Spacer(modifier = Modifier.height(8.dp))
            Text(copy.dashboardTitle, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f * contentOpacity))
        }
    }
}

@Composable
private fun FrostedCard(content: @Composable ColumnScope.() -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(14.dp, RoundedCornerShape(24.dp), ambientColor = Color.Black.copy(alpha = 0.08f), spotColor = Color.Black.copy(alpha = 0.08f))
            .clip(RoundedCornerShape(24.dp))
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.surface.copy(alpha = 0.94f),
                        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.74f)
                    )
                )
            )
            .border(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.06f), RoundedCornerShape(24.dp))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(18.dp),
            content = content
        )
    }
}

@Composable
private fun ToolbarCircleButton(icon: ImageVector, description: String, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = CircleShape,
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.82f),
        shadowElevation = 4.dp
    ) {
        Box(modifier = Modifier.size(38.dp), contentAlignment = Alignment.Center) {
            Icon(icon, contentDescription = description, modifier = Modifier.size(18.dp))
        }
    }
}

@Composable
private fun SectionEyebrow(text: String) {
    Text(
        text = text.uppercase(),
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.48f)
    )
}

@Composable
private fun HeroSheetCard(title: String, body: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(
                        Color(0xFFF96F42).copy(alpha = 0.92f),
                        Color(0xFFF7AD3B).copy(alpha = 0.86f),
                        Color(0xFF3EADE0).copy(alpha = 0.82f)
                    )
                )
            )
            .padding(20.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleLarge, color = ColorWhite)
            Text(body, style = MaterialTheme.typography.bodyMedium, color = ColorWhite.copy(alpha = 0.9f))
        }
    }
}

@Composable
private fun GradientActionButton(
    text: String,
    enabled: Boolean,
    loading: Boolean,
    icon: ImageVector,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(16.dp),
        color = Color.Transparent
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    if (enabled) {
                        Brush.linearGradient(listOf(Color(0xFF24A8D8), Color(0xFF1B83AF)))
                    } else {
                        Brush.linearGradient(listOf(Color.Gray.copy(alpha = 0.35f), Color.Gray.copy(alpha = 0.22f)))
                    }
                )
                .padding(vertical = 16.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                if (loading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = ColorWhite
                    )
                } else {
                    Icon(icon, contentDescription = null, tint = ColorWhite)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(text, color = ColorWhite, style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}

@Composable
private fun AtmosphereBackground() {
    val isDark = androidx.compose.foundation.isSystemInDarkTheme()
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colors = if (isDark) {
                        listOf(Color(0xFF151821), Color(0xFF1D2231), Color(0xFF17151B))
                    } else {
                        listOf(Color(0xFFF7F5E6), Color(0xFFE6F2F7), Color(0xFFF4EAF6))
                    }
                )
            )
    ) {
        Box(
            modifier = Modifier
                .size(220.dp)
                .offset(x = 160.dp, y = (-180).dp)
                .clip(CircleShape)
                .background(GoldenSun.copy(alpha = 0.18f))
                .align(Alignment.TopEnd)
        )
        Box(
            modifier = Modifier
                .size(260.dp)
                .offset(x = (-170).dp, y = 260.dp)
                .clip(CircleShape)
                .background(SkyBlue.copy(alpha = 0.14f))
                .align(Alignment.BottomStart)
        )
    }
}

private val WarmGradientStart = Color(0xFFF96F42)

private fun severityColor(severity: HazardSeverity): Color = when (severity) {
    HazardSeverity.NONE, HazardSeverity.COLD_YELLOW, HazardSeverity.COLD_ORANGE, HazardSeverity.COLD_RED -> CalmGreen
    HazardSeverity.HEAT_YELLOW -> AlertYellow
    HazardSeverity.HEAT_ORANGE -> AlertOrange
    HazardSeverity.HEAT_RED -> AlertRed
}

private fun severityIcon(severity: HazardSeverity): ImageVector = when (severity) {
    HazardSeverity.NONE, HazardSeverity.COLD_YELLOW, HazardSeverity.COLD_ORANGE, HazardSeverity.COLD_RED -> Icons.Rounded.Verified
    HazardSeverity.HEAT_YELLOW, HazardSeverity.HEAT_ORANGE -> Icons.Rounded.ReportProblem
    HazardSeverity.HEAT_RED -> Icons.Rounded.WarningAmber
}

@Composable
private fun worksiteTitleColor(severity: HazardSeverity): Color =
    if (severity == HazardSeverity.NONE) MaterialTheme.colorScheme.onSurface else ColorWhite

@Composable
private fun worksiteDetailColor(severity: HazardSeverity): Color =
    if (severity == HazardSeverity.NONE) MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f) else ColorWhite.copy(alpha = 0.82f)
