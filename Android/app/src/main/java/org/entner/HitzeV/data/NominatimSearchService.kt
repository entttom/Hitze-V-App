package org.entner.HitzeV.data

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.entner.HitzeV.BuildConfig
import org.entner.HitzeV.model.AddressSearchResult
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.util.Locale
import kotlin.coroutines.cancellation.CancellationException

class NominatimSearchService(
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val userAgent: String = DEFAULT_USER_AGENT
) {
    private val json = Json { ignoreUnknownKeys = true }
    private val cacheLock = Any()
    private val searchCache = object : LinkedHashMap<String, List<AddressSearchResult>>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, List<AddressSearchResult>>?): Boolean =
            size > MAX_CACHE_ENTRIES
    }

    suspend fun search(query: String, languageTag: String): NominatimSearchResult = withContext(ioDispatcher) {
        val cacheKey = "${languageTag.lowercase(Locale.ROOT)}|${query.lowercase(Locale.ROOT)}"
        synchronized(cacheLock) { searchCache[cacheKey] }?.let { cached ->
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
            setRequestProperty("Accept-Language", languageTag)
            setRequestProperty("User-Agent", userAgent)
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

            synchronized(cacheLock) { searchCache[cacheKey] = results }
            NominatimSearchResult.Success(results)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            NominatimSearchResult.Failure(error.localizedMessage ?: "Address search failed.")
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
        val city: String? = null
    )

    private companion object {
        const val MAX_CACHE_ENTRIES = 16
        // Nominatim usage policy requires an identifying User-Agent with a contact URL.
        val DEFAULT_USER_AGENT = "HitzeV Android/${BuildConfig.VERSION_NAME} (+https://github.com/entttom/Hitze-V-App)"
    }
}

sealed interface NominatimSearchResult {
    data class Success(val results: List<AddressSearchResult>) : NominatimSearchResult
    data class Failure(val message: String) : NominatimSearchResult
}
