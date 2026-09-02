package com.rustskinanalyzer.data.repository

import com.rustskinanalyzer.BuildConfig
import com.rustskinanalyzer.data.local.YoutubeMentionDao
import com.rustskinanalyzer.data.local.YoutubeMentionEntity
import com.rustskinanalyzer.data.model.Skin
import com.rustskinanalyzer.data.model.YoutuberMention
import com.rustskinanalyzer.data.model.YoutuberUsageSummary
import com.rustskinanalyzer.data.remote.YoutubeApi
import com.rustskinanalyzer.domain.SkinNameMatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.format.DateTimeFormatter

class YoutubeAnalysisRepository(
    private val youtubeApi: YoutubeApi,
    private val mentionDao: YoutubeMentionDao
) {
    /**
     * Шукає відео за період [fromMillis, toMillis], фільтрує ті, де реально
     * згадується назва скіну (а не лише слово з запиту), тягне статистику
     * переглядів і кешує результат локально.
     */
    suspend fun refreshMentionsForSkin(skin: Skin, fromMillis: Long, toMillis: Long) {
        val query = SkinNameMatcher.buildSearchQuery(skin.weapon, skin.displayName)
        val searchResponse = youtubeApi.searchVideos(
            query = query,
            publishedAfterIso = toIso(fromMillis),
            publishedBeforeIso = toIso(toMillis),
            apiKey = BuildConfig.YOUTUBE_API_KEY
        )

        val candidateIds = searchResponse.items.mapNotNull { it.id.videoId }
        if (candidateIds.isEmpty()) return

        val statsResponse = youtubeApi.getVideoStatistics(
            commaSeparatedVideoIds = candidateIds.joinToString(","),
            apiKey = BuildConfig.YOUTUBE_API_KEY
        )

        val matched = statsResponse.items.filter { video ->
            SkinNameMatcher.isMentioned(skin.displayName, video.snippet.title + " " + video.snippet.description)
        }

        val entities = matched.map { video ->
            YoutubeMentionEntity(
                videoId = video.id,
                skinMarketHashName = skin.marketHashName,
                channelTitle = video.snippet.channelTitle,
                videoTitle = video.snippet.title,
                publishedAtMillis = Instant.parse(video.snippet.publishedAt).toEpochMilli(),
                viewCount = video.statistics?.viewCount?.toLongOrNull() ?: 0L,
                fetchedAtMillis = System.currentTimeMillis()
            )
        }
        mentionDao.insertAll(entities)
    }

    fun observeMentions(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<YoutuberMention>> =
        mentionDao.observeForSkin(marketHashName, fromMillis, toMillis).map { list ->
            list.map {
                YoutuberMention(it.videoId, it.channelTitle, it.videoTitle, it.publishedAtMillis, it.viewCount, it.skinMarketHashName)
            }
        }

    fun observeUsageSummary(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<YoutuberUsageSummary> =
        observeMentions(marketHashName, fromMillis, toMillis).map { mentions ->
            YoutuberUsageSummary(
                skinMarketHashName = marketHashName,
                periodStartMillis = fromMillis,
                periodEndMillis = toMillis,
                mentionCount = mentions.size,
                totalViews = mentions.sumOf { it.viewCount },
                topChannels = mentions.groupBy { it.channelTitle }
                    .toList()
                    .sortedByDescending { (_, vids) -> vids.sumOf { it.viewCount } }
                    .take(5)
                    .map { it.first }
            )
        }

    private fun toIso(millis: Long): String =
        DateTimeFormatter.ISO_INSTANT.format(Instant.ofEpochMilli(millis))
}
