package org.entner.HitzeV.ui.components

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.tooling.preview.PreviewFontScale
import androidx.compose.ui.tooling.preview.PreviewLightDark
import androidx.compose.ui.tooling.preview.PreviewScreenSizes
import org.entner.HitzeV.model.ResolvedLanguage
import org.entner.HitzeV.ui.copy.Copybook
import org.entner.HitzeV.ui.theme.HitzeVTheme

@PreviewLightDark
@PreviewFontScale
@PreviewScreenSizes
annotation class HitzeVPreviews

@Composable
fun PreviewSurface(german: Boolean = false, content: @Composable () -> Unit) {
    HitzeVTheme(darkTheme = isSystemInDarkTheme()) {
        CompositionLocalProvider(
            LocalCopybook provides Copybook(if (german) ResolvedLanguage.DE else ResolvedLanguage.EN)
        ) {
            Surface(color = MaterialTheme.colorScheme.background, content = content)
        }
    }
}
