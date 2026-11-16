package org.entner.HitzeV.ui.dashboard

import androidx.compose.runtime.Immutable
import org.entner.HitzeV.DashboardUiState
import org.entner.HitzeV.LoadStatus
import org.entner.HitzeV.model.HazardSeverity
import java.time.Instant

enum class DashboardStatus {
    /** No worksites configured. */
    EMPTY,

    /** No warning known yet and at least one worksite is still loading. */
    LOADING,

    /** No warning known, but data for at least one worksite is missing or outdated. */
    UNKNOWN,

    /** Heat warning in at least one worksite (shown even if other worksites failed). */
    WARNING,

    /** No heat warning, UV ≥ 5 somewhere, all data fresh. */
    UV_ONLY,

    /** All worksites have fresh data and nothing to warn about. */
    CLEAR
}

@Immutable
data class DashboardSummary(
    val status: DashboardStatus,
    val highestSeverity: HazardSeverity,
    val warningCount: Int,
    val uvAffectedCount: Int,
    val highestUv: Double?,
    val maxApparentTemperature: Double?,
    val oldestUpdate: Instant?,
    val failedCount: Int
)

fun showsUvWarning(uvIndex: Double?): Boolean = uvIndex != null && uvIndex >= 5.0

fun DashboardUiState.summary(): DashboardSummary {
    val loadsForWorksites = worksites.map { loads[it.id] }
    val snapshots = loadsForWorksites.mapNotNull { it?.snapshot }
    val highestSeverity = snapshots.maxByOrNull { it.severity.level }?.severity ?: HazardSeverity.NONE
    val warningCount = snapshots.count { it.severity.isHeatWarning }
    val uvAffectedCount = snapshots.count { showsUvWarning(it.uvIndex) }
    val allFresh = worksites.isNotEmpty() && loadsForWorksites.all { load ->
        load?.status == LoadStatus.LOADED &&
            load.snapshot?.forecasts?.firstOrNull()?.date == today
    }
    val anyLoading = loadsForWorksites.any { it == null || it.status == LoadStatus.LOADING }

    val status = when {
        worksites.isEmpty() -> DashboardStatus.EMPTY
        warningCount > 0 -> DashboardStatus.WARNING
        !allFresh && anyLoading -> DashboardStatus.LOADING
        !allFresh -> DashboardStatus.UNKNOWN
        uvAffectedCount > 0 -> DashboardStatus.UV_ONLY
        else -> DashboardStatus.CLEAR
    }

    return DashboardSummary(
        status = status,
        highestSeverity = highestSeverity,
        warningCount = warningCount,
        uvAffectedCount = uvAffectedCount,
        highestUv = snapshots.mapNotNull { it.uvIndex }.maxOrNull(),
        maxApparentTemperature = snapshots.mapNotNull { it.apparentTemperature }.maxOrNull(),
        oldestUpdate = snapshots.minOfOrNull { it.updatedAt },
        failedCount = loadsForWorksites.count { it?.status == LoadStatus.FAILED }
    )
}
