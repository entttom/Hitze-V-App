package org.entner.HitzeV.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.entner.HitzeV.model.AddressSearchResult
import java.net.HttpURLConnection
import java.net.URLEncoder
import java.net.URL
import java.nio.charset.StandardCharsets
import java.util.Locale

class NominatimSearchService(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true }
    private val searchCache = linkedMapOf<String, List<AddressSearchResult>>()

    suspend fun search(query: String): NominatimSearchResult = withContext(Dispatchers.IO) {
        searchCache[query.lowercase(Locale.ROOT)]?.let { cached ->
            return@withContext NominatimSearchResult.Success(cached)
        }

        val encodedQuery = URLEncoder.encode(query, StandardCharsets.UTF_8.name())
        val url = URL(
            "https://nominatim.openstreetmap.org/search" +
                "?format=jsonv2" +
                "&countrycodes=at" +
                "&addressdetails=1" +
                "&limit=6" +
                "&q=$encodedQuery"
        )

        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 10_000
            readTimeout = 10_000
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Accept-Language", Locale.getDefault().toLanguageTag())
            setRequestProperty("User-Agent", "Hitze-V Android (${context.packageName})")
        }

        try {
            val statusCode = connection.responseCode
            if (statusCode !in 200..299) {
                return@withContext NominatimSearchResult.Failure("Nominatim HTTP $statusCode")
            }

            val body = connection.inputStream.bufferedReader().use { it.readText() }
            val results = json.decodeFromString<List<NominatimItem>>(body)
                .mapNotNull(::mapResult)
                .distinctBy { it.id }
                .take(6)

            searchCache[query.lowercase(Locale.ROOT)] = results
            trimCache()

            NominatimSearchResult.Success(results)
        } catch (error: Exception) {
            NominatimSearchResult.Failure(error.localizedMessage ?: "Adresssuche fehlgeschlagen.")
        } finally {
            connection.disconnect()
        }
    }

    private fun mapResult(item: NominatimItem): AddressSearchResult? {
        val latitude = item.latitude.toDoubleOrNull() ?: return null
        val longitude = item.longitude.toDoubleOrNull() ?: return null
        val title = item.name?.trim()?.takeIf { it.isNotEmpty() }
            ?: item.address?.road?.trim()?.takeIf { it.isNotEmpty() }
            ?: item.address?.city?.trim()?.takeIf { it.isNotEmpty() }
            ?: item.displayName.substringBefore(",").trim().takeIf { it.isNotEmpty() }
            ?: return null
        val subtitle = item.displayName.trim().ifEmpty { title }
        val key = "${subtitle.lowercase(Locale.ROOT)}|${"%.4f".format(Locale.US, latitude)}|${"%.4f".format(Locale.US, longitude)}"

        return AddressSearchResult(
            id = key,
            title = title,
            subtitle = subtitle,
            latitude = latitude,
            longitude = longitude
        )
    }

    private fun trimCache() {
        while (searchCache.size > 16) {
            val firstKey = searchCache.entries.firstOrNull()?.key ?: return
            searchCache.remove(firstKey)
        }
    }

    @Serializable
    private data class NominatimItem(
        @SerialName("lat")
        val latitude: String,
        @SerialName("lon")
        val longitude: String,
        @SerialName("display_name")
        val displayName: String,
        @SerialName("name")
        val name: String? = null,
        val address: NominatimAddress? = null
    )

    @Serializable
    private data class NominatimAddress(
        val road: String? = null,
        @SerialName("house_number")
        val houseNumber: String? = null,
        val city: String? = null,
        val town: String? = null,
        val village: String? = null
    )
}

sealed interface NominatimSearchResult {
    data class Success(val results: List<AddressSearchResult>) : NominatimSearchResult
    data class Failure(val message: String) : NominatimSearchResult
}
