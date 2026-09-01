package com.rustskinanalyzer.data.remote

import kotlinx.serialization.Serializable
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * YouTube Data API v3. Потрібен безкоштовний ключ з Google Cloud Console
 * (увімкнути "YouTube Data API v3"). Квота за замовчуванням: 10 000 "units"/день;
 * search.list коштує 100 units за запит — тобто ~100 пошуків/добу безкоштовно.
 * Тому в MVP шукаємо по одному скіну за раз, а не масово по всій базі щоразу.
 */
interface YoutubeApi {
    @GET("search")
    suspend fun searchVideos(
        @Query("q") query: String,
        @Query("part") part: String = "snippet",
        @Query("type") type: String = "video",
        @Query("order") order: String = "relevance",
        @Query("publishedAfter") publishedAfterIso: String,
        @Query("publishedBefore") publishedBeforeIso: String,
        @Query("maxResults") maxResults: Int = 25,
        @Query("regionCode") regionCode: String = "US",
        @Query("key") apiKey: String
    ): YoutubeSearchResponseDto

    /** Другий виклик потрібен, бо search.list не повертає статистику переглядів. */
    @GET("videos")
    suspend fun getVideoStatistics(
        @Query("id") commaSeparatedVideoIds: String,
        @Query("part") part: String = "statistics,snippet",
        @Query("key") apiKey: String
    ): YoutubeVideosResponseDto

    companion object {
        const val BASE_URL = "https://www.googleapis.com/youtube/v3/"
    }
}

@Serializable
data class YoutubeSearchResponseDto(
    val items: List<YoutubeSearchItemDto> = emptyList()
)

@Serializable
data class YoutubeSearchItemDto(
    val id: YoutubeVideoIdDto,
    val snippet: YoutubeSnippetDto
)

@Serializable
data class YoutubeVideoIdDto(val videoId: String? = null)

@Serializable
data class YoutubeSnippetDto(
    val title: String,
    val description: String,
    val channelTitle: String,
    val publishedAt: String
)

@Serializable
data class YoutubeVideosResponseDto(
    val items: List<YoutubeVideoItemDto> = emptyList()
)

@Serializable
data class YoutubeVideoItemDto(
    val id: String,
    val snippet: YoutubeSnippetDto,
    val statistics: YoutubeStatisticsDto? = null
)

@Serializable
data class YoutubeStatisticsDto(
    val viewCount: String? = null
)
