package org.entner.HitzeV.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.entner.HitzeV.model.DailyForecast
import org.entner.HitzeV.model.GeoCoordinate
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.WarningTimeRange
import org.entner.HitzeV.model.WorksiteSnapshot
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.util.Locale

class DashboardDataService(
    private val appStorage: AppStorage
) {
    private val json = Json { ignoreUnknownKeys = true }
    private val defaultGeosphereBaseUrl = "https://warnungen.zamg.at/wsapp/api/getWarningsForCoords"
    private val openMeteoBaseUrl = "https://api.open-meteo.com/v1/forecast"
    private val viennaZoneId = ZoneId.of("Europe/Vienna")

    suspend fun fetchSnapshot(coordinate: GeoCoordinate): WorksiteSnapshot = coroutineScope {
        val geoSphereResult = async { fetchGeoSphere(coordinate) }
        val openMeteoResult = async { fetchOpenMeteo(coordinate) }

        val geoResult = geoSphereResult.await()
        val meteoResult = openMeteoResult.await()

        val today = LocalDate.now(viennaZoneId)
        val forecasts = (0..3).map { offset ->
            val date = today.plusDays(offset.toLong())
            val severity = highestHazardSeverity(date, geoResult.warnings)
            val warningTimeRanges = warningTimeRangesForDate(date, geoResult.warnings)
            val uvIndex = meteoResult.daily.uvIndexMax.getOrNull(offset)
            val apparentTemperature = meteoResult.daily.apparentTemperatureMax.getOrNull(offset)

            DailyForecast(
                id = date.toString(),
                date = date,
                severity = severity,
                apparentTemperatureMax = apparentTemperature,
                uvIndexMax = uvIndex,
                warningTimeRanges = warningTimeRanges
            )
        }

        val todayForecast = forecasts.firstOrNull()
        WorksiteSnapshot(
            municipalityId = geoResult.municipalityId,
            municipalityName = geoResult.municipalityName,
            severity = todayForecast?.severity ?: HazardSeverity.NONE,
            uvIndex = todayForecast?.uvIndexMax,
            apparentTemperature = todayForecast?.apparentTemperatureMax,
            forecasts = forecasts,
            updatedAt = Instant.now()
        )
    }

    suspend fun resolveMunicipalityForCoordinate(coordinate: GeoCoordinate): ResolvedMunicipality {
        return fetchGeoSphere(coordinate)
    }

    private suspend fun fetchGeoSphere(coordinate: GeoCoordinate): ResolvedMunicipality {
        val geosphereBaseUrl = appStorage.customGeoSphereUrl.first().ifBlank { defaultGeosphereBaseUrl }
        val url = "$geosphereBaseUrl?lat=${coordinate.latitude.asQueryValue()}&lon=${coordinate.longitude.asQueryValue()}"
        val root = performGet(url)

        if (root["type"].asStringOrNull()?.equals("error", ignoreCase = true) == true) {
            throw DashboardDataError.MunicipalityNotFound(
                root["msg"].asStringOrNull() ?: "Could not find municipality for coordinates."
            )
        }

        val properties = root["properties"]?.jsonObject ?: throw DashboardDataError.InvalidGeoSphereResponse
        val municipalityProperties = properties["location"]?.jsonObject
            ?.get("properties")
            ?.jsonObject ?: throw DashboardDataError.InvalidGeoSphereResponse

        val municipalityId = municipalityProperties["gemeindenr"].municipalityValue()
            ?: throw DashboardDataError.InvalidGeoSphereResponse
        val municipalityName = municipalityProperties["name"].asStringOrNull() ?: "Gemeinde $municipalityId"

        val warnings = properties["warnings"]?.jsonArray?.mapNotNull { warningElement ->
            parseWarning(warningElement.jsonObject)
        }.orEmpty()

        return ResolvedMunicipality(
            municipalityId = municipalityId,
            municipalityName = municipalityName,
            warnings = warnings
        )
    }

    private suspend fun fetchOpenMeteo(coordinate: GeoCoordinate): OpenMeteoForecastResponse {
        val url = buildString {
            append(openMeteoBaseUrl)
            append("?latitude=${coordinate.latitude.asQueryValue()}")
            append("&longitude=${coordinate.longitude.asQueryValue()}")
            append("&daily=uv_index_max,apparent_temperature_max")
            append("&timezone=Europe/Vienna")
            append("&forecast_days=4")
        }

        val root = performGet(url)
        return json.decodeFromString(root.toString())
    }

    private suspend fun performGet(urlString: String): JsonObject = withContext(Dispatchers.IO) {
        val connection = (URL(urlString).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 10_000
            readTimeout = 10_000
            doInput = true
        }

        try {
            val statusCode = connection.responseCode
            if (statusCode !in 200..299) {
                val errorBody = connection.errorStream?.bufferedReader()?.use { it.readText() }.orEmpty()
                val parsedMunicipalityMessage = runCatching {
                    json.parseToJsonElement(errorBody).jsonObject
                }.getOrNull()?.municipalityNotFoundMessage()
                if (!parsedMunicipalityMessage.isNullOrBlank()) {
                    throw DashboardDataError.MunicipalityNotFound(parsedMunicipalityMessage)
                }
                throw DashboardDataError.Network("HTTP $statusCode")
            }

            val body = connection.inputStream.bufferedReader().use { it.readText() }
            json.parseToJsonElement(body).jsonObject
        } catch (error: DashboardDataError) {
            throw error
        } catch (error: Exception) {
            throw DashboardDataError.Network(error.localizedMessage ?: "Unknown network error")
        } finally {
            connection.disconnect()
        }
    }

    private fun parseWarning(objectValue: JsonObject): GeoSphereWarning? {
        val properties = objectValue["properties"]?.jsonObject ?: return null
        val warningTypeCandidates = listOfNotNull(
            properties["wtype"].asInt(),
            properties["warntypid"].asInt(),
            properties["rawinfo"]?.jsonObject?.get("wtype").asInt(),
            properties["rawfinfo"]?.jsonObject?.get("wtype").asInt()
        )
        val warningLevelCandidates = listOfNotNull(
            properties["warnstufeid"].asInt(),
            properties["wlevel"].asInt(),
            properties["rawinfo"]?.jsonObject?.get("wlevel").asInt(),
            properties["rawfinfo"]?.jsonObject?.get("wlevel").asInt()
        )

        return GeoSphereWarning(
            warningTypeId = warningTypeCandidates.firstOrNull(),
            warningTypeCandidates = warningTypeCandidates,
            warningLevel = warningLevelCandidates.maxOrNull() ?: 0,
            warningTypeText = properties["warning_type"].asStringOrNull(),
            start = properties["start"].asStringOrNull()
                ?: properties["begin"].asStringOrNull()
                ?: properties["rawinfo"]?.jsonObject?.get("start").asStringOrNull()
                ?: properties["rawfinfo"]?.jsonObject?.get("start").asStringOrNull(),
            end = properties["end"].asStringOrNull()
                ?: properties["rawinfo"]?.jsonObject?.get("end").asStringOrNull()
                ?: properties["rawfinfo"]?.jsonObject?.get("end").asStringOrNull()
        )
    }

    data class ResolvedMunicipality(
        val municipalityId: String,
        val municipalityName: String,
        val warnings: List<GeoSphereWarning>
    )

    data class GeoSphereWarning(
        val warningTypeId: Int?,
        val warningTypeCandidates: List<Int>,
        val warningLevel: Int,
        val warningTypeText: String?,
        val start: String?,
        val end: String?
    )

    @Serializable
    private data class OpenMeteoForecastResponse(
        val daily: OpenMeteoDaily = OpenMeteoDaily()
    )

    @Serializable
    private data class OpenMeteoDaily(
        val time: List<String> = emptyList(),
        @SerialName("uv_index_max")
        val uvIndexMax: List<Double?> = emptyList(),
        @SerialName("apparent_temperature_max")
        val apparentTemperatureMax: List<Double?> = emptyList()
    )

    companion object {
        private val localGeosphereDateTimeFormatters = listOf(
            DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm", Locale.GERMANY),
            DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm", Locale.US)
        )

        private data class DailyHeatWarning(
            val level: Int,
            val start: Instant?,
            val end: Instant?
        )

        internal fun parseGeosphereTimestamp(value: String?): Instant? {
            val trimmed = value?.trim().orEmpty()
            if (trimmed.isEmpty()) return null

            trimmed.toDoubleOrNull()?.let { numericValue ->
                val epochMillis = if (numericValue > 100_000_000_000) {
                    numericValue.toLong()
                } else {
                    (numericValue * 1000).toLong()
                }
                return Instant.ofEpochMilli(epochMillis)
            }

            return try {
                Instant.parse(trimmed)
            } catch (_: DateTimeParseException) {
                localGeosphereDateTimeFormatters.firstNotNullOfOrNull { formatter ->
                    runCatching {
                        LocalDateTime.parse(trimmed, formatter)
                            .atZone(ZoneId.of("Europe/Vienna"))
                            .toInstant()
                    }.getOrNull()
                }
            }
        }

        internal fun highestHazardSeverity(
            targetDate: LocalDate,
            warnings: List<GeoSphereWarning>,
            zoneId: ZoneId = ZoneId.of("Europe/Vienna")
        ): HazardSeverity {
            val highestHeat = heatWarningsForDate(targetDate, warnings, zoneId)
                .maxOfOrNull(DailyHeatWarning::level) ?: 0
            return if (highestHeat > 0) HazardSeverity.heat(highestHeat) else HazardSeverity.NONE
        }

        internal fun warningTimeRangesForDate(
            targetDate: LocalDate,
            warnings: List<GeoSphereWarning>,
            zoneId: ZoneId = ZoneId.of("Europe/Vienna")
        ): List<WarningTimeRange> {
            val startOfDay = targetDate.atStartOfDay(zoneId).toInstant()
            val endOfDay = targetDate.plusDays(1).atStartOfDay(zoneId).minusNanos(1).toInstant()

            return heatWarningsForDate(targetDate, warnings, zoneId)
                .map { warning ->
                    WarningTimeRange(
                        start = maxOf(warning.start ?: startOfDay, startOfDay),
                        end = minOf(warning.end ?: endOfDay, endOfDay)
                    )
                }
                .sortedBy(WarningTimeRange::start)
                .fold(mutableListOf()) { merged, range ->
                    val lastRange = merged.lastOrNull()
                    if (lastRange == null || range.start.isAfter(lastRange.end)) {
                        merged += range
                    } else {
                        merged[merged.lastIndex] = lastRange.copy(end = maxOf(lastRange.end, range.end))
                    }
                    merged
                }
        }

        private fun heatWarningsForDate(
            targetDate: LocalDate,
            warnings: List<GeoSphereWarning>,
            zoneId: ZoneId
        ): List<DailyHeatWarning> {
            val startOfDay = targetDate.atStartOfDay(zoneId).toInstant()
            val endOfDay = targetDate.plusDays(1).atStartOfDay(zoneId).minusNanos(1).toInstant()

            return warnings.mapNotNull { warning ->
                val startDate = parseGeosphereTimestamp(warning.start)
                val endDate = parseGeosphereTimestamp(warning.end)
                val intersects = when {
                    startDate != null && endDate != null -> !(endDate.isBefore(startOfDay) || startDate.isAfter(endOfDay))
                    startDate != null -> !startDate.isAfter(endOfDay)
                    endDate != null -> !endDate.isBefore(startOfDay)
                    else -> true
                }

                if (!intersects || !isHeatWarning(warning)) {
                    null
                } else {
                    DailyHeatWarning(
                        level = warning.warningLevel,
                        start = startDate,
                        end = endDate
                    )
                }
            }
        }

        private fun isHeatWarning(warning: GeoSphereWarning): Boolean {
            if (warning.warningTypeCandidates.contains(6)) return true

            val type = warning.warningTypeId
            if (type != null) return false

            val textualType = warning.warningTypeText?.lowercase(Locale.ROOT).orEmpty()
            return textualType.contains("hitze") || textualType.contains("heat")
        }
    }
}

sealed class DashboardDataError(message: String) : Exception(message) {
    data object InvalidRequest : DashboardDataError("Ungueltige Anfrageparameter.")
    data object InvalidGeoSphereResponse : DashboardDataError("GeoSphere Antwort konnte nicht gelesen werden.")
    data class MunicipalityNotFound(val detail: String) : DashboardDataError("Gemeinde nicht gefunden: $detail")
    data class Network(val detail: String) : DashboardDataError("Netzwerkfehler: $detail")
}

private fun Double.asQueryValue(): String = String.format(Locale.US, "%.6f", this)

private fun JsonElement?.asInt(): Int? = this?.jsonPrimitive?.intOrNull

private fun JsonElement?.municipalityValue(): String? {
    val element = this ?: return null
    return if (element is JsonObject) element["value"].municipalityValue() else element.asStringOrNull()
}

private fun JsonElement?.asStringOrNull(): String? =
    runCatching { this?.jsonPrimitive?.content }
        .getOrNull()
        ?.takeIf { it.isNotBlank() }

private fun JsonObject.municipalityNotFoundMessage(): String? {
    val type = this["type"].asStringOrNull()?.lowercase(Locale.ROOT)
    if (type != "error") return null

    val message = this["msg"].asStringOrNull() ?: return "Could not find municipal for coords."
    val normalizedMessage = message.lowercase(Locale.ROOT)
    return if (
        normalizedMessage.contains("could not find municipal for coords") ||
        normalizedMessage.contains("could not find municipality") ||
        normalizedMessage.contains("municipal for coords")
    ) {
        message
    } else {
        null
    }
}
