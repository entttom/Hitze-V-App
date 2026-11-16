package org.entner.HitzeV.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily.Companion.SansSerif
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.Hyphens
import androidx.compose.ui.unit.sp

// Hyphens.Auto: long German compounds (e.g. "Push-Benachrichtigungen") otherwise break
// mid-word without a hyphen at large font scales.
val Typography = Typography(
    displayLarge = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.Black,
        fontSize = 36.sp,
        lineHeight = 40.sp
    ),
    displayMedium = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 30.sp,
        lineHeight = 34.sp
    ),
    titleLarge = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.Bold,
        fontSize = 22.sp,
        lineHeight = 28.sp
    ),
    titleMedium = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.Bold,
        fontSize = 18.sp,
        lineHeight = 24.sp
    ),
    bodyLarge = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp
    ),
    labelLarge = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 18.sp
    ),
    labelSmall = TextStyle(
        fontFamily = SansSerif,
        hyphens = Hyphens.Auto,
        fontWeight = FontWeight.SemiBold,
        fontSize = 11.sp,
        lineHeight = 14.sp
    )
)
