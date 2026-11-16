@file:OptIn(ExperimentalMaterial3Api::class)

package org.entner.HitzeV.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material.icons.rounded.NotificationsOff
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import org.entner.HitzeV.DashboardUiState
import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.AppTheme
import org.entner.HitzeV.model.Worksite
import org.entner.HitzeV.ui.components.BackTopAppBar
import org.entner.HitzeV.ui.components.HeroSheetCard
import org.entner.HitzeV.ui.components.HitzeVPreviews
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.PreviewSurface
import org.entner.HitzeV.ui.components.SectionCard
import org.entner.HitzeV.ui.components.SwitchRow
import org.entner.HitzeV.ui.components.readableWidth
import java.time.Year

@Stable
interface SettingsActions {
    fun onBack()
    fun onThemeChanged(theme: AppTheme)
    fun onLanguageChanged(language: AppLanguage)
    fun onPushEnabledChanged(enabled: Boolean)
    fun onWorksitePushChanged(worksiteId: String, enabled: Boolean)
    fun onOpenNotificationSettings()
    fun onOpenLink(url: String)
}

@Composable
fun SettingsScreen(state: DashboardUiState, actions: SettingsActions) {
    val copy = LocalCopybook.current
    val layoutDirection = LocalLayoutDirection.current
    var isShowingLanguageSheet by rememberSaveable { mutableStateOf(false) }

    if (isShowingLanguageSheet) {
        LanguageSheet(
            selected = state.appLanguage,
            onSelect = { language ->
                isShowingLanguageSheet = false
                actions.onLanguageChanged(language)
            },
            onDismiss = { isShowingLanguageSheet = false }
        )
    }

    Scaffold(
        contentWindowInsets = WindowInsets.safeDrawing,
        topBar = { BackTopAppBar(title = copy.settingsTitle, onBack = actions::onBack) }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = innerPadding.calculateTopPadding())
                .verticalScroll(rememberScrollState()),
            contentAlignment = Alignment.TopCenter
        ) {
            Column(
                modifier = Modifier
                    .readableWidth()
                    .padding(
                        start = innerPadding.calculateStartPadding(layoutDirection) + 16.dp,
                        end = innerPadding.calculateEndPadding(layoutDirection) + 16.dp,
                        top = 8.dp,
                        bottom = innerPadding.calculateBottomPadding() + 24.dp
                    ),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                HeroSheetCard(title = copy.settingsTitle, body = copy.settingsHeroBody)

                SectionCard(title = copy.appearanceSection) {
                    val options = listOf(
                        AppTheme.SYSTEM to copy.themeSystem,
                        AppTheme.LIGHT to copy.themeLight,
                        AppTheme.DARK to copy.themeDark
                    )
                    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                        options.forEachIndexed { index, (theme, label) ->
                            SegmentedButton(
                                selected = state.appTheme == theme,
                                onClick = { actions.onThemeChanged(theme) },
                                shape = SegmentedButtonDefaults.itemShape(index = index, count = options.size)
                            ) {
                                Text(label, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            }
                        }
                    }
                }

                SectionCard(title = copy.languageSection) {
                    Surface(
                        onClick = { isShowingLanguageSheet = true },
                        shape = RoundedCornerShape(16.dp),
                        color = MaterialTheme.colorScheme.surfaceContainerHigh,
                        modifier = Modifier
                            .fillMaxWidth()
                            .semantics { stateDescription = copy.languageOption(state.appLanguage) }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                text = copy.languageOption(state.appLanguage),
                                modifier = Modifier.weight(1f),
                                style = MaterialTheme.typography.bodyLarge
                            )
                            Icon(
                                imageVector = Icons.AutoMirrored.Rounded.KeyboardArrowRight,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                PushSection(state = state, actions = actions)

                SectionCard(title = copy.aboutSection) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(copy.dataSourceLine, style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center)
                        Text(copy.weatherAttributionLine, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
                        Text(copy.geocodingAttributionLine, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
                        Text(copy.copyrightLine(Year.now().value), textAlign = TextAlign.Center)
                        TextButton(onClick = { actions.onOpenLink(copy.legalLinkURL) }) {
                            Text(copy.legalLinkLabel)
                        }
                        Text(
                            text = copy.machineTranslationDisclaimer,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PushSection(state: DashboardUiState, actions: SettingsActions) {
    val copy = LocalCopybook.current
    val blocked = !state.notificationsAllowed
    val pushActive = state.isPushEnabled && !blocked

    SectionCard(title = copy.pushNotificationsSection) {
        Text(copy.pushNotificationsDescription, style = MaterialTheme.typography.bodyMedium)

        if (blocked) {
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.errorContainer,
                contentColor = MaterialTheme.colorScheme.onErrorContainer
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Icon(Icons.Rounded.NotificationsOff, contentDescription = null)
                        Text(copy.notificationsBlockedMessage, style = MaterialTheme.typography.bodyMedium)
                    }
                    FilledTonalButton(onClick = actions::onOpenNotificationSettings, modifier = Modifier.fillMaxWidth()) {
                        Text(copy.openNotificationSettingsButton, textAlign = TextAlign.Center)
                    }
                }
            }
        }

        SwitchRow(
            title = copy.pushNotificationsEnabledLabel,
            subtitle = copy.pushNotificationsEnabledDescription,
            checked = pushActive,
            enabled = !blocked,
            onCheckedChange = actions::onPushEnabledChanged
        )

        if (state.pushSyncFailed && !blocked) {
            Text(
                copy.pushSyncFailedMessage,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.error
            )
        }
    }

    SectionCard(title = copy.pushWorksitesSectionTitle) {
        if (state.worksites.isEmpty()) {
            Text(
                copy.pushNoWorksitesMessage,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        } else {
            state.worksites.forEach { worksite: Worksite ->
                SwitchRow(
                    title = worksite.name,
                    subtitle = worksite.address?.takeIf { it.isNotBlank() } ?: copy.pushWorksiteFallbackSubtitle,
                    checked = pushActive && worksite.id !in state.disabledPushWorksiteIds,
                    enabled = pushActive,
                    onCheckedChange = { enabled -> actions.onWorksitePushChanged(worksite.id, enabled) }
                )
            }
        }
    }
}

@Composable
private fun LanguageSheet(
    selected: AppLanguage,
    onSelect: (AppLanguage) -> Unit,
    onDismiss: () -> Unit
) {
    val copy = LocalCopybook.current
    ModalBottomSheet(onDismissRequest = onDismiss) {
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .selectableGroup(),
            contentPadding = PaddingValues(bottom = 24.dp)
        ) {
            items(AppLanguage.entries, key = { it.rawValue }) { language ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 56.dp)
                        .selectable(
                            selected = language == selected,
                            role = Role.RadioButton,
                            onClick = { onSelect(language) }
                        )
                        .padding(horizontal = 24.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    RadioButton(selected = language == selected, onClick = null)
                    Text(copy.languageOption(language), style = MaterialTheme.typography.bodyLarge)
                }
            }
        }
    }
}

private object PreviewSettingsActions : SettingsActions {
    override fun onBack() = Unit
    override fun onThemeChanged(theme: AppTheme) = Unit
    override fun onLanguageChanged(language: AppLanguage) = Unit
    override fun onPushEnabledChanged(enabled: Boolean) = Unit
    override fun onWorksitePushChanged(worksiteId: String, enabled: Boolean) = Unit
    override fun onOpenNotificationSettings() = Unit
    override fun onOpenLink(url: String) = Unit
}

@HitzeVPreviews
@Composable
private fun SettingsScreenPreview() {
    PreviewSurface {
        SettingsScreen(
            state = DashboardUiState(
                preferencesLoaded = true,
                hasCompletedOnboarding = true,
                notificationsAllowed = false,
                worksites = listOf(Worksite(id = "a", name = "Baustelle", address = "Hauptplatz 1, 8010 Graz", latitude = 47.0, longitude = 15.4))
            ),
            actions = PreviewSettingsActions
        )
    }
}
