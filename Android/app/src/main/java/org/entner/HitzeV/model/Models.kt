package org.entner.HitzeV.model

import kotlinx.serialization.Serializable
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

enum class HazardSeverity(val rawValue: Int, val level: Int) {
    NONE(0, 0),
    HEAT_YELLOW(11, 1),
    HEAT_ORANGE(12, 2),
    HEAT_RED(13, 3),
    COLD_YELLOW(21, 1),
    COLD_ORANGE(22, 2),
    COLD_RED(23, 3);

    companion object {
        fun heat(level: Int): HazardSeverity = when {
            level >= 3 -> HEAT_RED
            level == 2 -> HEAT_ORANGE
            level == 1 -> HEAT_YELLOW
            else -> NONE
        }

        fun cold(level: Int): HazardSeverity = when {
            level >= 3 -> COLD_RED
            level == 2 -> COLD_ORANGE
            level == 1 -> COLD_YELLOW
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
    val longitude: Double
) {
    val coordinate: GeoCoordinate
        get() = GeoCoordinate(latitude = latitude, longitude = longitude)

    val coordinateLabel: String
        get() = "%.4f, %.4f".format(latitude, longitude)
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
