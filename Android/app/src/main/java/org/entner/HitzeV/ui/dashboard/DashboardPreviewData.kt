package org.entner.HitzeV.ui.dashboard

import androidx.compose.ui.tooling.preview.PreviewParameterProvider
import org.entner.HitzeV.DashboardUiState
import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.LoadStatus
import org.entner.HitzeV.WorksiteLoad
import org.entner.HitzeV.model.DailyForecast
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.WarningTimeRange
import org.entner.HitzeV.model.Worksite
import org.entner.HitzeV.model.WorksiteSnapshot
import java.time.Instant
import java.time.LocalDate

/** Empty, loading, error, levels 2/3/4 and UV-only. */
class DashboardPreviewStateProvider : PreviewParameterProvider<DashboardUiState> {
    private val today: LocalDate = LocalDate.of(2026, 7, 7)
    private val updatedAt: Instant = Instant.parse("2026-07-07T06:30:00Z")
    private val worksites = listOf(
        Worksite(id = "a", name = "Baustelle Hauptbahnhof", address = "Am Hauptbahnhof 1, 1100 Wien", latitude = 48.18, longitude = 16.37, municipalityId = "90001"),
        Worksite(id = "b", name = "Gartenbau Graz", address = "Hauptplatz 1, 8010 Graz", latitude = 47.07, longitude = 15.43, municipalityId = "60101")
    )

    private fun snapshot(severity: HazardSeverity, uv: Double?, apparent: Double?): WorksiteSnapshot {
        val forecasts = (0..3).map { offset ->
            val date = today.plusDays(offset.toLong())
            val daySeverity = if (offset <= 1) severity else HazardSeverity.NONE
            DailyForecast(
                id = date.toString(),
                date = date,
                severity = daySeverity,
                apparentTemperatureMax = apparent?.minus(offset),
                uvIndexMax = uv,
                warningTimeRanges = if (daySeverity.isHeatWarning) {
                    listOf(
                        WarningTimeRange(
                            start = date.atTime(10, 0).atZone(DashboardViewModel.VIENNA).toInstant(),
                            end = date.atTime(18, 0).atZone(DashboardViewModel.VIENNA).toInstant()
                        )
                    )
                } else {
                    emptyList()
                }
            )
        }
        return WorksiteSnapshot(
            municipalityId = "90001",
            municipalityName = "Wien",
            severity = severity,
            uvIndex = uv,
            apparentTemperature = apparent,
            forecasts = forecasts,
            updatedAt = updatedAt
        )
    }

    private fun loaded(vararg snapshots: WorksiteSnapshot) = DashboardUiState(
        preferencesLoaded = true,
        worksites = worksites,
        today = today,
        hasCompletedOnboarding = true,
        loads = worksites.zip(snapshots.toList()).associate { (worksite, snapshot) ->
            worksite.id to WorksiteLoad(LoadStatus.LOADED, snapshot)
        }
    )

    override val values: Sequence<DashboardUiState> = sequenceOf(
        DashboardUiState(preferencesLoaded = true, hasCompletedOnboarding = true, today = today),
        DashboardUiState(preferencesLoaded = true, hasCompletedOnboarding = true, today = today, worksites = worksites, isRefreshing = true),
        loaded(snapshot(HazardSeverity.NONE, 3.0, 26.0)).let { state ->
            state.copy(loads = state.loads + ("b" to WorksiteLoad(LoadStatus.FAILED)))
        },
        loaded(snapshot(HazardSeverity.HEAT_YELLOW, 6.0, 31.4), snapshot(HazardSeverity.NONE, 4.0, null)),
        loaded(snapshot(HazardSeverity.HEAT_ORANGE, 7.0, 35.2), snapshot(HazardSeverity.HEAT_YELLOW, 6.5, 31.0)),
        loaded(snapshot(HazardSeverity.HEAT_RED, 8.0, 40.8), snapshot(HazardSeverity.HEAT_ORANGE, 7.5, 36.0)),
        loaded(snapshot(HazardSeverity.NONE, 6.4, 27.0), snapshot(HazardSeverity.NONE, 4.0, 25.0))
    )
}
