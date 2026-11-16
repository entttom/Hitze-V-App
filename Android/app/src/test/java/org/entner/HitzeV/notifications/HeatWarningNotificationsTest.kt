package org.entner.HitzeV.notifications

import org.junit.Assert.assertEquals
import org.junit.Test

class HeatWarningNotificationsTest {
    @Test
    fun legacyPushWithGkzUsesTheSameTagAsTheV2Warning() {
        assertEquals("hitze-60101", HeatWarningNotifications.warningTag("60101"))
    }

    @Test
    fun legacyPushWithoutGkzFallsBackToTheSharedTag() {
        assertEquals("hitze-legacy", HeatWarningNotifications.warningTag(null))
    }
}
