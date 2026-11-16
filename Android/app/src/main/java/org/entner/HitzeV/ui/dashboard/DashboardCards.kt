package org.entner.HitzeV.ui.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CloudOff
import androidx.compose.material.icons.rounded.HourglassTop
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Thermostat
import androidx.compose.material.icons.rounded.WarningAmber
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import org.entner.HitzeV.DashboardUiState
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.ui.components.HeroBrush
import org.entner.HitzeV.ui.components.LevelChip
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.SectionCard
import org.entner.HitzeV.ui.components.SectionHeading
import org.entner.HitzeV.ui.components.StatusChip
import org.entner.HitzeV.ui.components.spokenSummary
import org.entner.HitzeV.ui.copy.Copybook
import org.entner.HitzeV.ui.theme.ClearStyle
import org.entner.HitzeV.ui.theme.SeverityStyle
import org.entner.HitzeV.ui.theme.UvStyle
import org.entner.HitzeV.ui.theme.style

/** Above this font scale side-by-side tiles get too narrow to read. */
internal const val LARGE_FONT_SCALE = 1.3f

private val NeutralStatusStyle = SeverityStyle(
    container = Color(0xFFE8E2DE),
    content = Color(0xFF111111),
    icon = Icons.Rounded.CloudOff
)

@Composable
internal fun HeroCard(state: DashboardUiState, summary: DashboardSummary) {
    val copy = LocalCopybook.current
    val actionText = heroActionText(copy, summary)
    val countsKnown = summary.status != DashboardStatus.LOADING && summary.status != DashboardStatus.UNKNOWN

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(HeroBrush)
            .padding(20.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(
                text = copy.dashboardTitle,
                style = MaterialTheme.typography.displayMedium,
                color = Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics { heading() }
            )
            Text(
                text = copy.dashboardSubtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                HeroStatusChip(summary)
                Text(
                    text = actionText,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                HeroMetric(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Rounded.LocationOn,
                    label = copy.workplaceLabel,
                    value = state.worksites.size.toString()
                )
                HeroMetric(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Rounded.WarningAmber,
                    label = copy.warningsLabel,
                    value = if (countsKnown || summary.warningCount > 0) summary.warningCount.toString() else copy.notAvailableShort
                )
            }

            summary.oldestUpdate?.let { updated ->
                Text(
                    text = copy.updatedAt(updated),
                    style = MaterialTheme.typography.labelLarge,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

@Composable
private fun HeroStatusChip(summary: DashboardSummary) {
    val copy = LocalCopybook.current
    when (summary.status) {
        DashboardStatus.WARNING -> LevelChip(summary.highestSeverity)
        DashboardStatus.UV_ONLY -> StatusChip(UvStyle, copy.uvWarningBadge5Plus)
        DashboardStatus.CLEAR -> StatusChip(ClearStyle, copy.severityHeadline(HazardSeverity.NONE))
        DashboardStatus.UNKNOWN -> StatusChip(NeutralStatusStyle, copy.statusUnknown)
        DashboardStatus.LOADING -> CircularProgressIndicator(
            modifier = Modifier.size(24.dp),
            color = Color.White,
            strokeWidth = 2.dp
        )
        DashboardStatus.EMPTY -> Unit
    }
}

internal fun heroActionText(copy: Copybook, summary: DashboardSummary): String = when (summary.status) {
    DashboardStatus.EMPTY -> copy.noWorkplaces
    DashboardStatus.LOADING -> copy.loading
    DashboardStatus.UNKNOWN -> copy.warningsUnavailableMessage
    DashboardStatus.WARNING -> copy.severityAction(summary.highestSeverity)
    DashboardStatus.UV_ONLY -> copy.uvOnlyAction(summary.uvAffectedCount)
    DashboardStatus.CLEAR -> copy.severityAction(HazardSeverity.NONE)
}

@Composable
private fun HeroMetric(modifier: Modifier, icon: ImageVector, label: String, value: String) {
    val copy = LocalCopybook.current
    Surface(
        modifier = modifier.spokenSummary("$label: ${copy.spoken(value)}"),
        shape = RoundedCornerShape(14.dp),
        color = Color.Black.copy(alpha = 0.28f),
        contentColor = Color.White
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Icon(icon, contentDescription = null, modifier = Modifier.size(16.dp))
                Text(label, style = MaterialTheme.typography.labelLarge, textAlign = TextAlign.Center)
            }
            Text(value, style = MaterialTheme.typography.titleLarge)
        }
    }
}

@Composable
internal fun GlanceCard(summary: DashboardSummary) {
    val copy = LocalCopybook.current
    val stackTiles = LocalDensity.current.fontScale > LARGE_FONT_SCALE
    val riskStyle: SeverityStyle?
    val riskValue: String
    when (summary.status) {
        DashboardStatus.WARNING -> {
            riskStyle = summary.highestSeverity.style()
            riskValue = "${copy.severityHeadline(summary.highestSeverity)} · ${copy.levelLabel(summary.highestSeverity.level)}"
        }
        DashboardStatus.UV_ONLY -> {
            riskStyle = UvStyle
            riskValue = copy.severityHeadline(HazardSeverity.HEAT_YELLOW)
        }
        DashboardStatus.CLEAR -> {
            riskStyle = ClearStyle
            riskValue = copy.severityHeadline(HazardSeverity.NONE)
        }
        DashboardStatus.LOADING -> {
            riskStyle = null
            riskValue = copy.loading
        }
        DashboardStatus.UNKNOWN -> {
            riskStyle = NeutralStatusStyle
            riskValue = copy.statusUnknown
        }
        DashboardStatus.EMPTY -> {
            riskStyle = null
            riskValue = copy.notAvailableShort
        }
    }

    SectionCard {
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            SectionHeading(title = copy.glanceTitle)
            Text(copy.glanceSubtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        val tiles: @Composable (Modifier) -> Unit = { tileModifier ->
            GlanceTile(
                modifier = tileModifier,
                title = copy.currentRiskTitle,
                value = riskValue,
                icon = riskStyle?.icon ?: Icons.Rounded.HourglassTop,
                badge = riskStyle
            )
            GlanceTile(
                modifier = tileModifier,
                title = copy.uvPeakTitle,
                value = copy.formatUv(summary.highestUv),
                icon = Icons.Rounded.WbSunny,
                badge = if (summary.uvAffectedCount > 0) UvStyle else null
            )
            GlanceTile(
                modifier = tileModifier,
                title = copy.apparentTitle,
                value = copy.formatTemperature(summary.maxApparentTemperature),
                icon = Icons.Rounded.Thermostat,
                badge = null
            )
        }
        if (stackTiles) {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) { tiles(Modifier.fillMaxWidth()) }
        } else {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) { tiles(Modifier.weight(1f)) }
        }
    }
}

@Composable
private fun GlanceTile(
    modifier: Modifier,
    title: String,
    value: String,
    icon: ImageVector,
    badge: SeverityStyle?
) {
    val copy = LocalCopybook.current
    Surface(
        modifier = modifier.spokenSummary("$title: ${copy.spoken(value)}"),
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceContainerHighest
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .clip(CircleShape)
                    .background(badge?.container ?: MaterialTheme.colorScheme.surfaceContainerLow),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = badge?.content ?: MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(18.dp)
                )
            }
            Text(value, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold)
            Text(title, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
