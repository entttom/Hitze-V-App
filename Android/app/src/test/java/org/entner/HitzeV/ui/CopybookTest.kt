package org.entner.HitzeV.ui

import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.ResolvedLanguage
import org.entner.HitzeV.ui.copy.Copybook
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.ZoneId
import java.util.Locale

class CopybookTest {
    @Test
    fun everyLanguageBuildsWithoutMissingTranslations() {
        ResolvedLanguage.entries.forEach { language ->
            val copy = Copybook(language)
            assertTrue(
                "${language.code} is missing: ${copy.missingTranslations}",
                copy.missingTranslations.isEmpty()
            )
        }
    }

    @Test
    fun missingTranslationFallsBackToEnglish() {
        val copy = Copybook(ResolvedLanguage.PL)
        assertEquals("Key without translation", copy.t("Schlüssel ohne Übersetzung", "Key without translation"))
        assertEquals(listOf("Key without translation"), copy.missingTranslations)
    }

    @Test
    fun appNameIsHitzeVAndRegulationStaysHitzeVWithHyphen() {
        ResolvedLanguage.entries.forEach { language ->
            val copy = Copybook(language)
            assertEquals("HitzeV", copy.shortTitle)
            val redAction = copy.severityAction(HazardSeverity.HEAT_RED)
            assertTrue("${language.code}: $redAction", redAction.contains("Hitze-V"))
            assertFalse("${language.code}: $redAction", redAction.contains("Heat-V"))
        }
        assertEquals("Sofort Schutzmaßnahmen nach Hitze-V umsetzen.", Copybook(ResolvedLanguage.DE).severityAction(HazardSeverity.HEAT_RED))
        assertEquals(
            "Take protective measures as required by the Hitze-V immediately.",
            Copybook(ResolvedLanguage.EN).severityAction(HazardSeverity.HEAT_RED)
        )
    }

    @Test
    fun onboardingPushTextMentionsUvLimitationInGermanAndEnglish() {
        assertTrue(Copybook(ResolvedLanguage.DE).onboardingPushText.contains("UV-Warnmeldungen"))
        assertTrue(Copybook(ResolvedLanguage.EN).onboardingPushText.contains("UV warnings"))
        ResolvedLanguage.entries.forEach { language ->
            val text = Copybook(language).onboardingPushText
            assertFalse("${language.code}: $text", text.contains("next step") || text.contains("nächsten Schritt"))
        }
    }

    @Test
    fun uvOnlyActionIsCountNeutralInEveryLanguage() {
        ResolvedLanguage.entries.forEach { language ->
            val copy = Copybook(language)
            listOf(1, 2, 5, 22).forEach { count ->
                assertTrue(copy.uvOnlyAction(count).contains(count.toString()))
            }
        }
    }

    @Test
    fun temperatureUsesDegreeSignAndLocaleDecimalSeparator() {
        assertEquals("31,4 °C", Copybook(ResolvedLanguage.DE).formatTemperature(31.44))
        assertEquals("31.4 °C", Copybook(ResolvedLanguage.EN).formatTemperature(31.44))
        assertEquals("—", Copybook(ResolvedLanguage.EN).formatTemperature(null))
        assertEquals("UV ≥ 5", Copybook(ResolvedLanguage.FR).uvWarningBadge5Plus)
    }

    @Test
    fun updatedAtUsesLocalizedShortTime() {
        val instant = Instant.parse("2026-07-07T12:05:00Z")
        val vienna = ZoneId.of("Europe/Vienna")
        assertEquals("Stand 14:05", Copybook(ResolvedLanguage.DE).updatedAt(instant, vienna))
        assertTrue(Copybook(ResolvedLanguage.EN).updatedAt(instant, vienna).startsWith("Updated 2:05"))
    }

    @Test
    fun copyrightConjunctionIsLocalized() {
        assertTrue(Copybook(ResolvedLanguage.EN).copyrightLine(2026).contains(" and "))
        assertTrue(Copybook(ResolvedLanguage.DE).copyrightLine(2026).contains(" und "))
    }

    @Test
    fun appLanguageMapsLocalesBothWays() {
        assertEquals(AppLanguage.DE, AppLanguage.fromLocale(Locale.forLanguageTag("de-AT")))
        assertEquals(AppLanguage.SYSTEM, AppLanguage.fromLocale(Locale.forLanguageTag("ja-JP")))
        assertEquals("pt-PT", AppLanguage.PT.localeTag)
        assertEquals(null, AppLanguage.SYSTEM.localeTag)
        assertEquals(ResolvedLanguage.EN, AppLanguage.SYSTEM.resolvedLanguage(Locale.JAPAN))
    }
}
