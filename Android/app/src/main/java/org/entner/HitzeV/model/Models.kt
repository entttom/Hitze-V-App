package org.entner.HitzeV.model

import kotlinx.serialization.Serializable
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

enum class HazardSeverity(val level: Int) {
    NONE(0),
    HEAT_YELLOW(2),
    HEAT_ORANGE(3),
    HEAT_RED(4);

    val isHeatWarning: Boolean
        get() = this != NONE

    companion object {
        fun heat(level: Int): HazardSeverity = when {
            level >= 4 -> HEAT_RED
            level == 3 -> HEAT_ORANGE
            level == 2 -> HEAT_YELLOW
            else -> NONE
        }
    }
}

@Serializable
data class Worksite(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val address: String? = null,
    val latitude: Double,
    val longitude: Double,
    val municipalityId: String? = null
) {
    val coordinate: GeoCoordinate
        get() = GeoCoordinate(latitude = latitude, longitude = longitude)
}

data class GeoCoordinate(
    val latitude: Double,
    val longitude: Double
)

data class AddressSearchResult(
    val id: String,
    val title: String,
    val subtitle: String,
    val latitude: Double,
    val longitude: Double
)

data class DailyForecast(
    val id: String,
    val date: LocalDate,
    val severity: HazardSeverity,
    val apparentTemperatureMax: Double?,
    val uvIndexMax: Double?,
    val warningTimeRanges: List<WarningTimeRange> = emptyList()
)

data class WarningTimeRange(
    val start: Instant,
    val end: Instant
)

data class WorksiteSnapshot(
    val municipalityId: String,
    val municipalityName: String,
    val severity: HazardSeverity,
    val uvIndex: Double?,
    val apparentTemperature: Double?,
    val forecasts: List<DailyForecast>,
    val updatedAt: Instant
)

/** GeoSphere `gemeindenr`, normalised the same way as the backend topic name. */
fun normalizeMunicipalityId(raw: String): String = raw.replace(Regex("\\s+"), "")
