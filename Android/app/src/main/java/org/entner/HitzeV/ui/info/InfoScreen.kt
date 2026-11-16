@file:OptIn(ExperimentalMaterial3Api::class)

package org.entner.HitzeV.ui.info

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Call
import androidx.compose.material.icons.rounded.Thermostat
import androidx.compose.material.icons.rounded.WarningAmber
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.ui.components.BackTopAppBar
import org.entner.HitzeV.ui.components.HitzeVPreviews
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.PreviewSurface
import org.entner.HitzeV.ui.components.SectionCard
import org.entner.HitzeV.ui.components.readableWidth
import org.entner.HitzeV.ui.components.spokenSummary
import org.entner.HitzeV.ui.copy.Copybook
import org.entner.HitzeV.ui.theme.OrangeStyle
import org.entner.HitzeV.ui.theme.RedStyle
import org.entner.HitzeV.ui.theme.SeverityStyle
import org.entner.HitzeV.ui.theme.UvStyle
import org.entner.HitzeV.ui.theme.style

@Composable
fun InfoScreen(
    onBack: () -> Unit,
    onOpenUrl: (String) -> Unit,
    snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
) {
    val copy = LocalCopybook.current
    val layoutDirection = LocalLayoutDirection.current

    Scaffold(
        contentWindowInsets = WindowInsets.safeDrawing,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = { BackTopAppBar(title = copy.infoScreenTitle, onBack = onBack) }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = innerPadding.calculateTopPadding()),
            contentAlignment = Alignment.TopCenter
        ) {
            LazyColumn(
                modifier = Modifier
                    .readableWidth()
                    .fillMaxHeight(),
                contentPadding = PaddingValues(
                    start = innerPadding.calculateStartPadding(layoutDirection) + 16.dp,
                    end = innerPadding.calculateEndPadding(layoutDirection) + 16.dp,
                    top = 8.dp,
                    bottom = innerPadding.calculateBottomPadding() + 24.dp
                ),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item(key = "heatHeader") { InfoSectionHeader(copy.infoScreenHeatMeasuresTitle) }
                item(key = "scale") { InfoScaleCard(copy) }
                item(key = "intro") { InfoIntroCard(copy.infoIntro) }
                item(key = "program") {
                    StructuredInfoCard(copy.heatProgramSection, Icons.Rounded.Thermostat, OrangeStyle, onOpenUrl)
                }
                item(key = "emergency") {
                    StructuredInfoCard(copy.heatEmergencySection, Icons.Rounded.WarningAmber, RedStyle, onOpenUrl)
                }
                item(key = "uvHeader") { InfoSectionHeader(copy.infoScreenUvMeasuresTitle) }
                item(key = "uv") {
                    StructuredInfoCard(copy.uvSection, Icons.Rounded.WbSunny, UvStyle, onOpenUrl)
                }
            }
        }
    }
}

@Composable
private fun InfoSectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.onBackground,
        modifier = Modifier
            .padding(top = 8.dp)
            .semantics { heading() }
    )
}

@Composable
private fun InfoIntroCard(text: String) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = MaterialTheme.colorScheme.tertiaryContainer,
        contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(text = text, modifier = Modifier.padding(18.dp), style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
private fun InfoScaleCard(copy: Copybook) {
    val entries = listOf(
        HazardSeverity.HEAT_YELLOW to copy.infoScreenLevel2Title,
        HazardSeverity.HEAT_ORANGE to copy.infoScreenLevel3Title,
        HazardSeverity.HEAT_RED to copy.infoScreenLevel4Title
    )
    SectionCard(title = copy.infoScreenHeatScaleTitle) {
        entries.forEach { (severity, title) ->
            val style = severity.style()
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(MaterialTheme.colorScheme.surfaceContainerHigh)
                    .spokenSummary("${copy.levelLabel(severity.level)}: $title")
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(style.container),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(style.icon, contentDescription = null, tint = style.content)
                }
                Text(text = title, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
            }
        }
    }
}

@Composable
private fun StructuredInfoCard(
    section: Copybook.InfoSection,
    icon: ImageVector,
    accent: SeverityStyle,
    onOpenUrl: (String) -> Unit
) {
    SectionCard {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(accent.container),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, contentDescription = null, tint = accent.content, modifier = Modifier.size(20.dp))
            }
            Text(
                text = section.title,
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.semantics { heading() }
            )
        }

        section.groups.forEachIndexed { index, group ->
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = group.title,
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.semantics { heading() }
                )
                group.bullets.forEach { bullet -> InfoBulletRow(bullet = bullet, onOpenUrl = onOpenUrl) }
            }
            if (index < section.groups.lastIndex) {
                HorizontalDivider()
            }
        }
    }
}

@Composable
private fun InfoBulletRow(bullet: Copybook.InfoBullet, onOpenUrl: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                modifier = Modifier
                    .padding(top = 8.dp)
                    .size(6.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.onSurfaceVariant)
            )
            Text(text = bullet.text, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium)
        }

        bullet.cta?.let { cta ->
            Button(
                onClick = { onOpenUrl(cta.url) },
                modifier = Modifier.align(Alignment.CenterHorizontally),
                colors = ButtonDefaults.buttonColors(containerColor = RedStyle.container, contentColor = RedStyle.content)
            ) {
                Icon(Icons.Rounded.Call, contentDescription = null, modifier = Modifier.size(18.dp))
                Text(cta.label, modifier = Modifier.padding(start = 8.dp))
            }
        }
    }
}

@HitzeVPreviews
@Composable
private fun InfoScreenPreview() {
    PreviewSurface {
        InfoScreen(onBack = {}, onOpenUrl = {})
    }
}
