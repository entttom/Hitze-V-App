package org.entner.HitzeV.dashboard

import org.entner.HitzeV.DashboardUiState
import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.LoadStatus
import org.entner.HitzeV.WorksiteLoad
import org.entner.HitzeV.model.DailyForecast
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.Worksite
import org.entner.HitzeV.model.WorksiteSnapshot
import org.entner.HitzeV.ui.dashboard.DashboardStatus
import org.entner.HitzeV.ui.dashboard.summary
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.LocalDate

class DashboardStateTest {
    private val today = LocalDate.of(2026, 7, 7)
    private val now = Instant.parse("2026-07-07T10:00:00Z")
    private val worksiteA = Worksite(id = "a", name = "A", latitude = 48.2, longitude = 16.4)
    private val worksiteB = Worksite(id = "b", name = "B", latitude = 47.1, longitude = 15.4)

    private fun snapshot(
        severity: HazardSeverity = HazardSeverity.NONE,
        uv: Double? = 2.0,
        date: LocalDate = today,
        updatedAt: Instant = now
    ) = WorksiteSnapshot(
        municipalityId = "90001",
        municipalityName = "Wien",
        severity = severity,
        uvIndex = uv,
        apparentTemperature = 25.0,
        forecasts = listOf(DailyForecast(date.toString(), date, severity, 25.0, uv)),
        updatedAt = updatedAt
    )

    private fun state(vararg loads: Pair<Worksite, WorksiteLoad?>) = DashboardUiState(
        preferencesLoaded = true,
        today = today,
        worksites = loads.map { it.first },
        loads = loads.mapNotNull { (worksite, load) -> load?.let { worksite.id to it } }.toMap()
    )

    @Test
    fun allClearOnlyWhenEveryWorksiteHasFreshData() {
        val clear = state(
            worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot()),
            worksiteB to WorksiteLoad(LoadStatus.LOADED, snapshot())
        )
        assertEquals(DashboardStatus.CLEAR, clear.summary().status)

        val oneFailed = state(
            worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot()),
            worksiteB to WorksiteLoad(LoadStatus.FAILED)
        )
        assertEquals(DashboardStatus.UNKNOWN, oneFailed.summary().status)

        val stillLoading = state(
            worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot()),
            worksiteB to null
        )
        assertEquals(DashboardStatus.LOADING, stillLoading.summary().status)

        val yesterdaysData = state(worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot(date = today.minusDays(1))))
        assertEquals(DashboardStatus.UNKNOWN, yesterdaysData.summary().status)
    }

    @Test
    fun warningIsShownEvenIfAnotherWorksiteFailed() {
        val summary = state(
            worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot(HazardSeverity.HEAT_ORANGE)),
            worksiteB to WorksiteLoad(LoadStatus.FAILED)
        ).summary()

        assertEquals(DashboardStatus.WARNING, summary.status)
        assertEquals(HazardSeverity.HEAT_ORANGE, summary.highestSeverity)
        assertEquals(1, summary.failedCount)
    }

    @Test
    fun uvOnlyRequiresFreshDataAndUvAtLeastFive() {
        val summary = state(
            worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot(uv = 5.0)),
            worksiteB to WorksiteLoad(LoadStatus.LOADED, snapshot(uv = null))
        ).summary()

        assertEquals(DashboardStatus.UV_ONLY, summary.status)
        assertEquals(1, summary.uvAffectedCount)
    }

    @Test
    fun emptyStateHasNoStatus() {
        assertEquals(DashboardStatus.EMPTY, DashboardUiState(today = today).summary().status)
    }

    @Test
    fun needsRefreshAfterTenMinutesOrViennaDateChangeOrFailure() {
        val fresh = state(worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot(updatedAt = now)))
        assertFalse(DashboardViewModel.needsRefresh(fresh, now.plusSeconds(9 * 60)))
        assertTrue(DashboardViewModel.needsRefresh(fresh, now.plusSeconds(10 * 60)))

        val lateEvening = Instant.parse("2026-07-07T21:55:00Z")
        val evening = state(worksiteA to WorksiteLoad(LoadStatus.LOADED, snapshot(updatedAt = lateEvening)))
        assertTrue(DashboardViewModel.needsRefresh(evening, lateEvening.plusSeconds(6 * 60)))

        val failed = state(worksiteA to WorksiteLoad(LoadStatus.FAILED, snapshot(updatedAt = now)))
        assertTrue(DashboardViewModel.needsRefresh(failed, now))

        val loading = state(worksiteA to WorksiteLoad(LoadStatus.LOADING))
        assertFalse(DashboardViewModel.needsRefresh(loading, now))
    }
}
