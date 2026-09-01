package com.rustskinanalyzer.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "tracked_skins")
data class SkinEntity(
    @PrimaryKey val marketHashName: String,
    val displayName: String,
    val weapon: String,
    val iconUrl: String? = null,
    val addedAtMillis: Long
)

@Entity(tableName = "price_snapshots")
data class PriceSnapshotEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val skinMarketHashName: String,
    val timestampMillis: Long,
    val lowestPrice: Double?,
    val medianPrice: Double?,
    val volume: Int?
)

@Entity(tableName = "youtube_mentions")
data class YoutubeMentionEntity(
    @PrimaryKey val videoId: String,
    val skinMarketHashName: String,
    val channelTitle: String,
    val videoTitle: String,
    val publishedAtMillis: Long,
    val viewCount: Long,
    val fetchedAtMillis: Long
)
