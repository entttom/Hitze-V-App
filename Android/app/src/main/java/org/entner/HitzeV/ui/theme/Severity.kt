package org.entner.HitzeV.ui.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Dangerous
import androidx.compose.material.icons.rounded.Error
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import org.entner.HitzeV.model.HazardSeverity

/** Container/content pairs keep at least 4.5:1 contrast; each level also has its own icon shape. */
@Immutable
data class SeverityStyle(
    val container: Color,
    val content: Color,
    val icon: ImageVector
)

private val SignalBlack = Color(0xFF111111)
private val SignalWhite = Color(0xFFFFFFFF)

val ClearStyle = SeverityStyle(Color(0xFF2E9E5B), SignalBlack, Icons.Rounded.CheckCircle)
val YellowStyle = SeverityStyle(Color(0xFFF5C518), SignalBlack, Icons.Rounded.Error)
val OrangeStyle = SeverityStyle(Color(0xFFF08A24), SignalBlack, Icons.Rounded.Warning)
val RedStyle = SeverityStyle(Color(0xFFC62828), SignalWhite, Icons.Rounded.Dangerous)
val UvStyle = SeverityStyle(Color(0xFFF5C518), SignalBlack, Icons.Rounded.WbSunny)

fun HazardSeverity.style(): SeverityStyle = when (this) {
    HazardSeverity.NONE -> ClearStyle
    HazardSeverity.HEAT_YELLOW -> YellowStyle
    HazardSeverity.HEAT_ORANGE -> OrangeStyle
    HazardSeverity.HEAT_RED -> RedStyle
}
