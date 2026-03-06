package org.entner.HitzeV.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = GoldenSun,
    secondary = SkyBlue,
    tertiary = WarmOrange,
    background = DeepNight,
    surface = DeepSlate,
    surfaceVariant = SurfaceDark,
    onPrimary = DeepNight,
    onSecondary = DeepNight,
    onTertiary = DeepNight,
    onBackground = ColorWhite,
    onSurface = ColorWhite
)

private val LightColorScheme = lightColorScheme(
    primary = WarmOrange,
    secondary = SkyBlue,
    tertiary = GoldenSun,
    background = SandBackground,
    surface = SurfaceLight,
    surfaceVariant = MistBackground,
    onPrimary = ColorWhite,
    onSecondary = ColorWhite,
    onTertiary = DeepNight,
    onBackground = ColorBlack,
    onSurface = ColorBlack
)

@Composable
fun HitzeVTheme(
    darkTheme: Boolean,
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
