package org.entner.HitzeV

import org.entner.HitzeV.data.DashboardDataService
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.ResolvedLanguage
import org.entner.HitzeV.ui.copy.Copybook
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class ExampleUnitTest {
    @Test
    fun parseGeosphereTimestamp_supportsMilliseconds() {
        val timestamp = DashboardDataService.parseGeosphereTimestamp("1741111200000")

        assertNotNull(timestamp)
        assertEquals(Instant.ofEpochMilli(1741111200000), timestamp)
    }

    @Test
    fun highestHazardSeverity_usesOnlyWarningsForRequestedDay() {
        val severity = DashboardDataService.highestHazardSeverity(
            targetDate = LocalDate.parse("2026-07-10"),
            warnings = listOf(
                DashboardDataService.GeoSphereWarning(
                    warningTypeId = 6,
                    warningLevel = 3,
                    warningTypeText = "Hitze",
                    start = "2026-07-10T08:00:00Z",
                    end = "2026-07-10T18:00:00Z"
                ),
                DashboardDataService.GeoSphereWarning(
                    warningTypeId = 6,
                    warningLevel = 1,
                    warningTypeText = "Hitze",
                    start = "2026-07-11T08:00:00Z",
                    end = "2026-07-11T18:00:00Z"
                )
            )
        )

        assertEquals(HazardSeverity.HEAT_RED, severity)
    }

    @Test
    fun warningTimeRangesForDate_clipsAndMergesRangesWithinTheDay() {
        val zoneId = ZoneId.of("Europe/Vienna")
        val targetDate = LocalDate.parse("2026-07-10")

        val ranges = DashboardDataService.warningTimeRangesForDate(
            targetDate = targetDate,
            warnings = listOf(
                DashboardDataService.GeoSphereWarning(
                    warningTypeId = 6,
                    warningLevel = 1,
                    warningTypeText = "Hitze",
                    start = "2026-07-09T22:00:00Z",
                    end = "2026-07-10T08:00:00Z"
                ),
                DashboardDataService.GeoSphereWarning(
                    warningTypeId = 6,
                    warningLevel = 2,
                    warningTypeText = "Hitze",
                    start = "2026-07-10T07:30:00Z",
                    end = "2026-07-10T10:00:00Z"
                )
            ),
            zoneId = zoneId
        )

        assertEquals(1, ranges.size)
        assertEquals(targetDate.atStartOfDay(zoneId).toInstant(), ranges.first().start)
        assertTrue(ranges.first().end.isAfter(ranges.first().start))
    }

    @Test
    fun copybook_switchesBetweenGermanAndEnglish() {
        val german = Copybook(ResolvedLanguage.DE)
        val english = Copybook(ResolvedLanguage.EN)

        assertEquals("Willkommen bei Hitze-V", german.onboardingWelcomeTitle)
        assertEquals("Welcome to Hitze-V", english.onboardingWelcomeTitle)
        assertEquals("Stabil", german.severityHeadline(HazardSeverity.NONE))
        assertEquals("Critical", english.severityHeadline(HazardSeverity.HEAT_RED))
    }
}
