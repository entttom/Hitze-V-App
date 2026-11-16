@file:OptIn(ExperimentalLayoutApi::class)

package org.entner.HitzeV.ui.dashboard

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AccessTime
import androidx.compose.material.icons.rounded.CloudOff
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.MoreVert
import androidx.compose.material.icons.rounded.Thermostat
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.LoadStatus
import org.entner.HitzeV.WorksiteLoad
import org.entner.HitzeV.model.DailyForecast
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.Worksite
import org.entner.HitzeV.model.WorksiteSnapshot
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.StatusChip
import org.entner.HitzeV.ui.components.spokenSummary
import org.entner.HitzeV.ui.copy.Copybook
import org.entner.HitzeV.ui.theme.UvStyle
import org.entner.HitzeV.ui.theme.style
import java.time.LocalDate
import java.time.format.DateTimeFormatter

private val warningTimeFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm")

@Composable
internal fun WorksiteCard(
    worksite: Worksite,
    load: WorksiteLoad?,
    today: LocalDate,
    highlighted: Boolean,
    onRetry: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val copy = LocalCopybook.current
    var showDeleteConfirmation by rememberSaveable(worksite.id) { mutableStateOf(false) }
    var menuExpanded by remember { mutableStateOf(false) }
    val snapshot = load?.snapshot
    val severity = snapshot?.severity ?: HazardSeverity.NONE

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
                    Text(copy.deleteWorkplace, color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirmation = false }) { Text(copy.cancelButton) }
            }
        )
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .pointerInput(worksite.id) {
                detectTapGestures(onLongPress = { showDeleteConfirmation = true })
            }
            .semantics {
                customActions = listOf(
                    CustomAccessibilityAction(copy.deleteWorkplace) {
                        showDeleteConfirmation = true
                        true
                    }
                )
            },
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        border = if (highlighted) BorderStroke(3.dp, MaterialTheme.colorScheme.primary) else null
    ) {
        if (severity.isHeatWarning) {
            SeverityBanner(severity)
        }
        if (load?.status == LoadStatus.LOADING && snapshot != null) {
            LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 4.dp, top = 12.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(verticalAlignment = Alignment.Top) {
                WorksiteHeader(
                    worksite = worksite,
                    snapshot = snapshot,
                    modifier = Modifier.weight(1f)
                )
                Box {
                    IconButton(onClick = { menuExpanded = true }) {
                        Icon(Icons.Rounded.MoreVert, contentDescription = "${copy.moreOptionsLabel}: ${worksite.name}")
                    }
                    DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                        DropdownMenuItem(
                            text = { Text(copy.deleteWorkplace) },
                            leadingIcon = { Icon(Icons.Rounded.Delete, contentDescription = null) },
                            onClick = {
                                menuExpanded = false
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }

            Column(
                modifier = Modifier.padding(end = 12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                when {
                    snapshot != null -> SnapshotDetails(copy = copy, snapshot = snapshot, today = today)
                    load?.status == LoadStatus.FAILED -> Unit
                    else -> Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                        Text(copy.loading, style = MaterialTheme.typography.bodyMedium)
                    }
                }

                if (load?.status == LoadStatus.FAILED) {
                    LoadFailedRow(onRetry = onRetry)
                }
            }
        }
    }
}

@Composable
private fun SeverityBanner(severity: HazardSeverity) {
    val copy = LocalCopybook.current
    val style = severity.style()
    Surface(color = style.container, contentColor = style.content, modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(style.icon, contentDescription = null, modifier = Modifier.size(20.dp))
            Text(
                text = "${copy.levelLabel(severity.level)} · ${copy.severityHeadline(severity)}",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun WorksiteHeader(worksite: Worksite, snapshot: WorksiteSnapshot?, modifier: Modifier) {
    val copy = LocalCopybook.current
    val stackFacts = LocalDensity.current.fontScale > LARGE_FONT_SCALE

    val nameBlock: @Composable (Modifier) -> Unit = { blockModifier ->
        Column(modifier = blockModifier, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                worksite.name,
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.semantics { heading() }
            )
            if (!worksite.address.isNullOrBlank()) {
                Text(
                    text = worksite.address,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }

    val facts: @Composable () -> Unit = {
        if (snapshot != null) {
            MiniFact(Icons.Rounded.WbSunny, copy.uvPeakTitle, copy.formatUv(snapshot.uvIndex))
            MiniFact(Icons.Rounded.Thermostat, copy.apparentTitle, copy.formatTemperature(snapshot.apparentTemperature))
            if (showsUvWarning(snapshot.uvIndex)) {
                StatusChip(UvStyle, copy.uvWarningBadge5Plus)
            }
        }
    }

    if (stackFacts || snapshot == null) {
        Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            nameBlock(Modifier.fillMaxWidth())
            facts()
        }
    } else {
        Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            nameBlock(Modifier.weight(1f))
            Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp)) { facts() }
        }
    }
}

@Composable
private fun SnapshotDetails(copy: Copybook, snapshot: WorksiteSnapshot, today: LocalDate) {
    Text(
        snapshot.municipalityName,
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        snapshot.forecasts.forEach { forecast ->
            DailyForecastChip(forecast = forecast, today = today)
        }
    }

    val warningLines = snapshot.forecasts.mapNotNull { forecast ->
        formatWarningTimeRanges(copy, forecast)?.let { "${copy.todayTitle(forecast.date, today)}: $it" }
    }
    warningLines.forEach { line ->
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(Icons.Rounded.AccessTime, contentDescription = null, modifier = Modifier.size(16.dp))
            Text(line, style = MaterialTheme.typography.bodyMedium)
        }
    }

    Text(
        copy.updatedAt(snapshot.updatedAt),
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

@Composable
private fun LoadFailedRow(onRetry: () -> Unit) {
    val copy = LocalCopybook.current
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.errorContainer,
        contentColor = MaterialTheme.colorScheme.onErrorContainer
    ) {
        Row(
            modifier = Modifier.padding(start = 12.dp, end = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(Icons.Rounded.CloudOff, contentDescription = null, modifier = Modifier.size(18.dp))
            Text(copy.worksiteLoadFailed, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f, fill = false))
            TextButton(onClick = onRetry) { Text(copy.retryButton) }
        }
    }
}

@Composable
private fun MiniFact(icon: ImageVector, label: String, value: String) {
    val copy = LocalCopybook.current
    Row(
        modifier = Modifier.spokenSummary("$label: ${copy.spoken(value)}"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
private fun DailyForecastChip(forecast: DailyForecast, today: LocalDate) {
    val copy = LocalCopybook.current
    val severity = forecast.severity
    val style = severity.style()
    val dayLabel = copy.todayTitle(forecast.date, today)
    val temperature = copy.formatForecastTemperature(forecast.apparentTemperatureMax)
    val spoken = buildString {
        append(dayLabel)
        if (severity.isHeatWarning) append(", ").append(copy.levelLabel(severity.level))
        append(", ").append(copy.apparentTitle).append(' ').append(copy.spoken(copy.formatTemperature(forecast.apparentTemperatureMax)))
    }

    Surface(
        modifier = Modifier
            .widthIn(min = 56.dp)
            .spokenSummary(spoken),
        shape = RoundedCornerShape(12.dp),
        color = if (severity.isHeatWarning) style.container else MaterialTheme.colorScheme.surfaceContainerHighest,
        contentColor = if (severity.isHeatWarning) style.content else MaterialTheme.colorScheme.onSurface
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(dayLabel, style = MaterialTheme.typography.labelSmall)
            if (severity.isHeatWarning) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                    Icon(style.icon, contentDescription = null, modifier = Modifier.size(14.dp))
                    Text(severity.level.toString(), style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
                }
            }
            Text(temperature, style = MaterialTheme.typography.labelLarge)
        }
    }
}

internal fun formatWarningTimeRanges(copy: Copybook, forecast: DailyForecast): String? {
    if (forecast.warningTimeRanges.isEmpty()) return null

    val zone = DashboardViewModel.VIENNA
    val levelSuffix = if (forecast.severity.isHeatWarning) " (${copy.levelLabel(forecast.severity.level)})" else ""
    val startOfDay = forecast.date.atStartOfDay(zone).toInstant()
    val endThreshold = forecast.date.plusDays(1).atStartOfDay(zone).toInstant().minusSeconds(60)

    return forecast.warningTimeRanges.joinToString(" · ") { range ->
        if (range.start == startOfDay && !range.end.isBefore(endThreshold)) {
            "${copy.warningAllDay}$levelSuffix"
        } else {
            val startText = warningTimeFormatter.format(range.start.atZone(zone))
            val endText = warningTimeFormatter.format(range.end.atZone(zone))
            "$startText–$endText$levelSuffix"
        }
    }
}
