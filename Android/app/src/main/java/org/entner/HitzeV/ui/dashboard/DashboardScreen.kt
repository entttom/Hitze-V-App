@file:OptIn(ExperimentalMaterial3Api::class)

package org.entner.HitzeV.ui.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AddCircle
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.adaptive.currentWindowAdaptiveInfo
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import androidx.compose.ui.unit.dp
import androidx.window.core.layout.WindowSizeClass
import kotlinx.coroutines.delay
import org.entner.HitzeV.DashboardUiState
import org.entner.HitzeV.ui.components.HitzeVPreviews
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.MaxContentWidth
import org.entner.HitzeV.ui.components.PreviewSurface
import org.entner.HitzeV.ui.components.SectionHeading
import org.entner.HitzeV.ui.components.openExternalUri
import java.time.Year

@Stable
interface DashboardActions {
    fun onAddWorkplace()
    fun onOpenSettings()
    fun onOpenInfo()
    fun onRefresh()
    fun onRetryWorksite(worksiteId: String)
    fun onDeleteWorksite(worksiteId: String)
    fun onHighlightConsumed()
}

private val ExpandedMaxContentWidth = 1200.dp
private const val LEADING_ITEMS = 3

@Composable
fun DashboardScreen(
    state: DashboardUiState,
    actions: DashboardActions,
    snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
) {
    val copy = LocalCopybook.current
    val context = LocalContext.current
    val summary = remember(state.worksites, state.loads, state.today) { state.summary() }
    val expanded = currentWindowAdaptiveInfo().windowSizeClass
        .isWidthAtLeastBreakpoint(WindowSizeClass.WIDTH_DP_EXPANDED_LOWER_BOUND)
    val gridState = rememberLazyGridState()
    val layoutDirection = LocalLayoutDirection.current

    LaunchedEffect(state.highlightedMunicipalityId, state.worksites) {
        val target = state.highlightedMunicipalityId ?: return@LaunchedEffect
        val index = state.worksites.indexOfFirst { it.municipalityId == target }
        if (index >= 0) {
            gridState.animateScrollToItem(LEADING_ITEMS + index)
        }
        delay(4_000)
        actions.onHighlightConsumed()
    }

    Scaffold(
        contentWindowInsets = WindowInsets.safeDrawing,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Text(copy.shortTitle, modifier = Modifier.semantics { heading() })
                },
                navigationIcon = {
                    IconButton(onClick = actions::onOpenInfo) {
                        Icon(Icons.Rounded.Info, contentDescription = copy.infoButtonLabel)
                    }
                },
                actions = {
                    if (state.isRefreshing) {
                        Box(modifier = Modifier.size(48.dp), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        }
                    } else {
                        IconButton(onClick = actions::onRefresh, enabled = state.worksites.isNotEmpty()) {
                            Icon(Icons.Rounded.Refresh, contentDescription = copy.refreshButton)
                        }
                    }
                    IconButton(onClick = actions::onOpenSettings) {
                        Icon(Icons.Rounded.Settings, contentDescription = copy.settingsTitle)
                    }
                    IconButton(onClick = actions::onAddWorkplace) {
                        Icon(Icons.Rounded.AddCircle, contentDescription = copy.addWorkplaceTitle)
                    }
                }
            )
        }
    ) { innerPadding ->
        PullToRefreshBox(
            isRefreshing = state.isRefreshing,
            onRefresh = actions::onRefresh,
            modifier = Modifier
                .fillMaxSize()
                .padding(top = innerPadding.calculateTopPadding())
        ) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(if (expanded) 2 else 1),
                    state = gridState,
                    modifier = Modifier
                        .widthIn(max = if (expanded) ExpandedMaxContentWidth else MaxContentWidth)
                        .fillMaxSize(),
                    contentPadding = PaddingValues(
                        start = innerPadding.calculateStartPadding(layoutDirection) + 16.dp,
                        end = innerPadding.calculateEndPadding(layoutDirection) + 16.dp,
                        top = 8.dp,
                        bottom = innerPadding.calculateBottomPadding() + 32.dp
                    ),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    item(key = "hero", span = { GridItemSpan(if (expanded) 1 else maxLineSpan) }) {
                        HeroCard(state = state, summary = summary)
                    }
                    item(key = "glance", span = { GridItemSpan(if (expanded) 1 else maxLineSpan) }) {
                        GlanceCard(summary = summary)
                    }
                    item(key = "worksitesHeading", span = { GridItemSpan(maxLineSpan) }) {
                        SectionHeading(
                            title = copy.monitoredWorkplacesTitle,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                    if (state.worksites.isEmpty()) {
                        item(key = "empty", span = { GridItemSpan(maxLineSpan) }) {
                            EmptyWorksites(onAdd = actions::onAddWorkplace)
                        }
                    } else {
                        items(state.worksites, key = { it.id }) { worksite ->
                            WorksiteCard(
                                worksite = worksite,
                                load = state.loads[worksite.id],
                                today = state.today,
                                highlighted = worksite.municipalityId != null &&
                                    worksite.municipalityId == state.highlightedMunicipalityId,
                                onRetry = { actions.onRetryWorksite(worksite.id) },
                                onDelete = { actions.onDeleteWorksite(worksite.id) }
                            )
                        }
                    }
                    item(key = "footer", span = { GridItemSpan(maxLineSpan) }) {
                        LegalFooter(onOpenLink = { context.openExternalUri(it) })
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyWorksites(onAdd: () -> Unit) {
    val copy = LocalCopybook.current
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(copy.noWorkplaces, style = MaterialTheme.typography.bodyLarge)
            TextButton(onClick = onAdd) { Text(copy.addWorkplaceTitle) }
        }
    }
}

@Composable
private fun LegalFooter(onOpenLink: (String) -> Unit) {
    val copy = LocalCopybook.current
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = "${copy.dataSourceLine} · ${copy.weatherAttributionLine}",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Text(
            text = copy.copyrightLine(Year.now().value),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        TextButton(onClick = { onOpenLink(copy.legalLinkURL) }) {
            Text(copy.legalLinkLabel)
        }
    }
}

private object PreviewDashboardActions : DashboardActions {
    override fun onAddWorkplace() = Unit
    override fun onOpenSettings() = Unit
    override fun onOpenInfo() = Unit
    override fun onRefresh() = Unit
    override fun onRetryWorksite(worksiteId: String) = Unit
    override fun onDeleteWorksite(worksiteId: String) = Unit
    override fun onHighlightConsumed() = Unit
}

@HitzeVPreviews
@Composable
private fun DashboardScreenPreview(
    @PreviewParameter(DashboardPreviewStateProvider::class) state: DashboardUiState
) {
    PreviewSurface {
        DashboardScreen(state = state, actions = PreviewDashboardActions)
    }
}

@Preview(name = "Warning level 4, German", locale = "de")
@Composable
private fun DashboardScreenGermanPreview() {
    PreviewSurface(german = true) {
        DashboardScreen(state = DashboardPreviewStateProvider().values.elementAt(5), actions = PreviewDashboardActions)
    }
}
