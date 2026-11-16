package org.entner.HitzeV.dashboard

import org.entner.HitzeV.DashboardViewModel
import org.entner.HitzeV.PushSyncRequest
import org.entner.HitzeV.model.Worksite
import org.junit.Assert.assertEquals
import org.junit.Test

class PushSyncRequestTest {
    private fun worksite(id: String, gkz: String?) =
        Worksite(id = id, name = id, latitude = 48.2, longitude = 16.4, municipalityId = gkz)

    @Test
    fun completeWhenEveryPushEnabledWorksiteHasAGkz() {
        val request = DashboardViewModel.pushSyncRequest(
            listOf(worksite("a", "60101"), worksite("b", "30101"), worksite("c", "60101")),
            disabledIds = emptySet()
        )
        assertEquals(PushSyncRequest(setOf("60101", "30101"), complete = true), request)
    }

    @Test
    fun unknownGkzMakesTheRequestIncompleteButKeepsTheKnownOnes() {
        val request = DashboardViewModel.pushSyncRequest(
            listOf(worksite("a", "60101"), worksite("b", null), worksite("c", " ")),
            disabledIds = emptySet()
        )
        assertEquals(PushSyncRequest(setOf("60101"), complete = false), request)
    }

    @Test
    fun disabledWorksitesWithoutGkzDoNotMakeTheRequestIncomplete() {
        val request = DashboardViewModel.pushSyncRequest(
            listOf(worksite("a", "60101"), worksite("b", null), worksite("c", "30101")),
            disabledIds = setOf("b", "c")
        )
        assertEquals(PushSyncRequest(setOf("60101"), complete = true), request)
    }

    @Test
    fun emptyListIsComplete() {
        assertEquals(PushSyncRequest(emptySet(), complete = true), DashboardViewModel.pushSyncRequest(emptyList(), emptySet()))
    }

    @Test
    fun failedRefreshOfOneWorksiteDoesNotBlockFillingTheOthers() {
        val stored = listOf(worksite("a", null), worksite("b", null), worksite("c", "10101"))
        // "b" failed to load, so it has no entry; "c" keeps its GKZ.
        val merged = DashboardViewModel.mergeMunicipalityIds(stored, mapOf("a" to "60101", "c" to " "))

        assertEquals(listOf("60101", null, "10101"), merged.map { it.municipalityId })
        assertEquals(
            PushSyncRequest(setOf("60101", "10101"), complete = false),
            DashboardViewModel.pushSyncRequest(merged, emptySet())
        )
    }
}
