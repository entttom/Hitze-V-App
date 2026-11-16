package org.entner.HitzeV.push

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull
import java.time.DateTimeException
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

const val PUSH_COPY_ASSET = "push-copy.json"

@Serializable
data class PushCopyFile(
    val version: Int = 1,
    val fallbackLanguage: String = "en",
    val languages: Map<String, PushCopyLanguage> = emptyMap()
)

@Serializable
data class PushCopyLanguage(
    val title: String? = null,
    val titleEscalated: String? = null,
    val titleUpdated: String? = null,
    val titleTest: String? = null,
    val levelNames: Map<String, String> = emptyMap(),
    val dayToday: String? = null,
    val dayTomorrow: String? = null,
    val weekdays: List<String> = emptyList(),
    val allDay: String? = null,
    val timeRange: String? = null,
    val bodyNew: String? = null,
    val bodyEscalated: String? = null,
    val bodyUpdated: String? = null,
    val bodyTodayTomorrow: String? = null,
    val bodyTest: String? = null
)

data class PushDay(
    val date: LocalDate,
    val level: Int,
    val start: Instant?,
    val end: Instant?
)

data class PushMessage(
    val type: String,
    val event: String,
    val gkz: String,
    val name: String,
    val days: List<PushDay>,
    val sentAt: Instant?
) {
    val isTest: Boolean get() = event == EVENT_TEST || type == TYPE_TEST

    companion object {
        const val EVENT_NEW = "new"
        const val EVENT_ESCALATED = "escalated"
        const val EVENT_UPDATED = "updated"
        const val EVENT_TEST = "test"
        const val TYPE_TEST = "test"

        private val json = Json { ignoreUnknownKeys = true }

        /** Parses an FCM v2 data payload; returns null for anything that is not a v2 message. */
        fun fromData(data: Map<String, String>): PushMessage? {
            if (data["v"] != "2") return null
            val gkz = data["gkz"]?.replace(WHITESPACE, "").orEmpty()
            if (gkz.isEmpty()) return null
            return PushMessage(
                type = data["type"].orEmpty(),
                event = data["event"].orEmpty(),
                gkz = gkz,
                name = data["name"].orEmpty(),
                days = parseDays(data["days"]),
                sentAt = parseInstant(data["sentAt"])
            )
        }

        fun parseDays(raw: String?): List<PushDay> {
            if (raw.isNullOrBlank()) return emptyList()
            val array = runCatching { json.parseToJsonElement(raw) as? JsonArray }.getOrNull() ?: return emptyList()
            return array.mapNotNull { element ->
                val day = element as? JsonObject ?: return@mapNotNull null
                val date = (day["date"] as? JsonPrimitive)?.content
                    ?.let { runCatching { LocalDate.parse(it) }.getOrNull() }
                    ?: return@mapNotNull null
                val levelPrimitive = day["level"] as? JsonPrimitive ?: return@mapNotNull null
                val level = levelPrimitive.intOrNull ?: levelPrimitive.content.toIntOrNull() ?: return@mapNotNull null
                PushDay(
                    date = date,
                    level = level,
                    start = parseInstant((day["start"] as? JsonPrimitive)?.content),
                    end = parseInstant((day["end"] as? JsonPrimitive)?.content)
                )
            }.sortedBy(PushDay::date)
        }

        private fun parseInstant(value: String?): Instant? =
            value?.takeIf { it.isNotBlank() }?.let {
                try {
                    Instant.parse(it)
                } catch (_: DateTimeException) {
                    null
                }
            }
    }
}

data class RenderedPush(val title: String, val body: String)

/** Renders v2 pushes exactly as described in docs/push-contract-v2.md (shared with backend and iOS). */
class PushCopyRenderer(private val copy: PushCopyFile) {
    val availableLanguages: Set<String> get() = copy.languages.keys
    val fallbackLanguage: String get() = copy.fallbackLanguage

    /** First candidate present in the copy file wins; otherwise the copy file's fallback language. */
    fun resolveLanguage(candidates: List<String?>): String =
        candidates.asSequence()
            .mapNotNull { it?.trim()?.lowercase(Locale.ROOT)?.substringBefore('-')?.substringBefore('_') }
            .firstOrNull { it in copy.languages }
            ?: copy.fallbackLanguage

    fun render(message: PushMessage, languageCode: String, now: Instant): RenderedPush {
        val language = resolveLanguage(listOf(languageCode))
        val strings = Strings(copy.languages[language], copy.languages[copy.fallbackLanguage])

        if (message.isTest) {
            return RenderedPush(
                title = strings.text { it.titleTest },
                body = fill(strings.text { it.bodyTest }, mapOf("name" to message.name))
            )
        }

        val title = when (message.event) {
            PushMessage.EVENT_ESCALATED -> strings.text { it.titleEscalated }
            PushMessage.EVENT_UPDATED -> strings.text { it.titleUpdated }
            else -> strings.text { it.title }
        }

        val days = message.days
        val today = now.atZone(VIENNA).toLocalDate()
        val body = when {
            days.size >= 2 && message.event != PushMessage.EVENT_UPDATED -> fill(
                strings.text { it.bodyTodayTomorrow },
                mapOf(
                    "name" to message.name,
                    "level1" to days[0].level.toString(),
                    "levelName1" to strings.levelName(days[0].level),
                    "time1" to time(days[0], strings),
                    "level2" to days[1].level.toString(),
                    "levelName2" to strings.levelName(days[1].level),
                    "time2" to time(days[1], strings)
                )
            )
            days.isNotEmpty() -> {
                val template = when (message.event) {
                    PushMessage.EVENT_ESCALATED -> strings.text { it.bodyEscalated }
                    PushMessage.EVENT_UPDATED -> strings.text { it.bodyUpdated }
                    else -> strings.text { it.bodyNew }
                }
                val day = days[0]
                fill(
                    template,
                    mapOf(
                        "day" to dayLabel(day.date, today, strings),
                        "name" to message.name,
                        "level" to day.level.toString(),
                        "levelName" to strings.levelName(day.level),
                        "time" to time(day, strings)
                    )
                )
            }
            else -> message.name
        }
        return RenderedPush(title, body)
    }

    private fun dayLabel(date: LocalDate, today: LocalDate, strings: Strings): String = when (date) {
        today -> strings.text { it.dayToday }
        today.plusDays(1) -> strings.text { it.dayTomorrow }
        else -> strings.weekday(date.dayOfWeek.value)
    }

    private fun time(day: PushDay, strings: Strings): String {
        val dayStart = day.date.atStartOfDay(VIENNA).toInstant()
        val nextDayStart = day.date.plusDays(1).atStartOfDay(VIENNA).toInstant()
        val start = day.start?.takeIf { it.isAfter(dayStart) }?.let(TIME_FORMAT::format) ?: "00:00"
        val end = day.end?.takeIf { it.isBefore(nextDayStart) }?.let(TIME_FORMAT::format) ?: "24:00"
        return if (start == "00:00" && end == "24:00") {
            strings.text { it.allDay }
        } else {
            fill(strings.text { it.timeRange }, mapOf("start" to start, "end" to end))
        }
    }

    private class Strings(private val primary: PushCopyLanguage?, private val fallback: PushCopyLanguage?) {
        fun text(select: (PushCopyLanguage) -> String?): String =
            primary?.let(select) ?: fallback?.let(select) ?: ""

        fun levelName(level: Int): String =
            primary?.levelNames?.get(level.toString())
                ?: fallback?.levelNames?.get(level.toString())
                ?: level.toString()

        fun weekday(isoDayOfWeek: Int): String =
            primary?.weekdays?.takeIf { it.size == 7 }?.get(isoDayOfWeek - 1)
                ?: fallback?.weekdays?.takeIf { it.size == 7 }?.get(isoDayOfWeek - 1)
                ?: ""
    }

    companion object {
        val VIENNA: ZoneId = ZoneId.of("Europe/Vienna")
        private val TIME_FORMAT: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm", Locale.ROOT).withZone(VIENNA)
        private val PLACEHOLDER = Regex("""\{([A-Za-z0-9]+)\}""")
        private val json = Json { ignoreUnknownKeys = true }

        fun fromJson(text: String): PushCopyRenderer = PushCopyRenderer(json.decodeFromString<PushCopyFile>(text))

        // Single pass so a municipality name containing "{level}" is never substituted again.
        internal fun fill(template: String, values: Map<String, String>): String =
            PLACEHOLDER.replace(template) { match -> values[match.groupValues[1]] ?: match.value }
    }
}

private val WHITESPACE = Regex("""\s+""")
