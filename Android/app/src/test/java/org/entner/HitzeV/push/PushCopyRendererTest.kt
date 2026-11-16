package org.entner.HitzeV.push

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.time.Instant

class PushCopyRendererTest {
    private val pushCopyText = File(requireNotNull(System.getProperty("hitzev.pushCopy"))).readText()
    private val examples = Json.parseToJsonElement(
        File(requireNotNull(System.getProperty("hitzev.pushCopyExamples"))).readText()
    ).jsonObject
    private val renderer = PushCopyRenderer.fromJson(pushCopyText)

    private fun cases(): List<JsonObject> = examples.getValue("cases").jsonArray.map { it.jsonObject }

    private fun messageFor(case: JsonObject): PushMessage {
        val event = case.getValue("event").jsonPrimitive.content
        val data = mapOf(
            "v" to "2",
            "type" to if (event == "test") "test" else "heat_warning",
            "event" to event,
            "gkz" to "60101",
            "name" to case.getValue("name").jsonPrimitive.content,
            "days" to (case["days"] as JsonArray).toString(),
            "warningIds" to "1",
            "sentAt" to case.getValue("now").jsonPrimitive.content
        )
        return requireNotNull(PushMessage.fromData(data)) { "case ${case["id"]} did not parse" }
    }

    @Test
    fun reproducesGoldenVectorsForGermanAndEnglish() {
        val cases = cases()
        assertTrue(cases.isNotEmpty())
        for (case in cases) {
            val expected = case.getValue("expected").jsonObject
            for (language in listOf("de", "en")) {
                val want = expected.getValue(language).jsonObject
                val now = Instant.parse(case.getValue("now").jsonPrimitive.content)
                val got = renderer.render(messageFor(case), language, now)
                val id = case.getValue("id").jsonPrimitive.content
                assertEquals("$id/$language title", want.getValue("title").jsonPrimitive.content, got.title)
                assertEquals("$id/$language body", want.getValue("body").jsonPrimitive.content, got.body)
            }
        }
    }

    @Test
    fun reproducesEveryLanguageListedInGoldenVectors() {
        for (case in cases()) {
            val now = Instant.parse(case.getValue("now").jsonPrimitive.content)
            for ((language, want) in case.getValue("expected").jsonObject) {
                if (language !in renderer.availableLanguages) continue
                val got = renderer.render(messageFor(case), language, now)
                assertEquals(want.jsonObject.getValue("title").jsonPrimitive.content, got.title)
                assertEquals(want.jsonObject.getValue("body").jsonPrimitive.content, got.body)
            }
        }
    }

    @Test
    fun rendersEveryLanguagePresentWithoutLeftoverPlaceholders() {
        assertTrue(renderer.availableLanguages.containsAll(listOf("de", "en")))
        for (language in renderer.availableLanguages) {
            for (case in cases()) {
                val now = Instant.parse(case.getValue("now").jsonPrimitive.content)
                val got = renderer.render(messageFor(case), language, now)
                assertTrue("$language empty title", got.title.isNotBlank())
                assertTrue("$language empty body", got.body.isNotBlank())
                assertFalse("$language placeholder left: ${got.body}", got.body.contains(Regex("""\{[A-Za-z0-9]+\}""")))
            }
        }
    }

    @Test
    fun unknownLanguageFallsBackToFallbackLanguage() {
        assertEquals(renderer.fallbackLanguage, renderer.resolveLanguage(listOf("xx")))
        assertEquals(renderer.fallbackLanguage, renderer.resolveLanguage(listOf(null)))
        assertEquals("de", renderer.resolveLanguage(listOf("de-AT")))
        val case = cases().first()
        val now = Instant.parse(case.getValue("now").jsonPrimitive.content)
        assertEquals(
            renderer.render(messageFor(case), renderer.fallbackLanguage, now),
            renderer.render(messageFor(case), "xx", now)
        )
    }

    @Test
    fun missingKeysFallBackPerKey() {
        val partial = PushCopyRenderer.fromJson(
            """{"fallbackLanguage":"en","languages":{"en":${Json.parseToJsonElement(pushCopyText).jsonObject.getValue("languages").jsonObject.getValue("en")},"xx":{"title":"T"}}}"""
        )
        val case = cases().first { it.getValue("event").jsonPrimitive.content == "new" }
        val now = Instant.parse(case.getValue("now").jsonPrimitive.content)
        val english = partial.render(messageFor(case), "en", now)
        val rendered = partial.render(messageFor(case), "xx", now)
        assertEquals("T", rendered.title)
        assertEquals(english.body, rendered.body)
    }

    @Test
    fun placeholdersInNamesAreNotExpandedTwice() {
        assertEquals("A {level} B", PushCopyRenderer.fill("{name} B", mapOf("name" to "A {level}", "level" to "3")))
    }

    @Test
    fun rejectsNonV2Payloads() {
        assertEquals(null, PushMessage.fromData(mapOf("title" to "x", "body" to "y")))
        assertEquals(null, PushMessage.fromData(mapOf("v" to "2")))
    }
}
