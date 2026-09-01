package com.rustskinanalyzer.data.model

/**
 * Скін, за яким користувач стежить.
 * marketHashName — точна назва предмета в Steam Market, напр. "AK-47 | Redline (Field-Tested)".
 * Для Rust предмети зазвичай мають вигляд "<Зброя> | <Назва скіну>".
 */
data class Skin(
    val marketHashName: String,
    val displayName: String,
    val weapon: String,
    val iconUrl: String? = null
)

/** Одна точка ціни, зібрана нашим застосунком у певний момент часу. */
data class PricePoint(
    val skinMarketHashName: String,
    val timestampMillis: Long,
    val lowestPrice: Double?,
    val medianPrice: Double?,
    val volume: Int?
)

/** Розрахований тренд для скіну за період. */
data class SkinTrend(
    val skinMarketHashName: String,
    val points: List<PricePoint>,
    val changePercent: Double?,
    val direction: TrendDirection
)

enum class TrendDirection { UP, DOWN, FLAT, UNKNOWN }

/** Відео на YouTube, у якому, ймовірно, згадується/показується скін. */
data class YoutuberMention(
    val videoId: String,
    val channelTitle: String,
    val videoTitle: String,
    val publishedAtMillis: Long,
    val viewCount: Long,
    val matchedSkinMarketHashName: String
)

/** Агреговані дані про використання скіну ютюберами за період. */
data class YoutuberUsageSummary(
    val skinMarketHashName: String,
    val periodStartMillis: Long,
    val periodEndMillis: Long,
    val mentionCount: Int,
    val totalViews: Long,
    val topChannels: List<String>
)
