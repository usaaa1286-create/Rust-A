package com.rustskinanalyzer.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface SkinDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(skin: SkinEntity)

    @Query("DELETE FROM tracked_skins WHERE marketHashName = :marketHashName")
    suspend fun delete(marketHashName: String)

    @Query("SELECT * FROM tracked_skins ORDER BY addedAtMillis DESC")
    fun observeAll(): Flow<List<SkinEntity>>
}

@Dao
interface PriceSnapshotDao {
    @Insert
    suspend fun insert(snapshot: PriceSnapshotEntity)

    @Query(
        "SELECT * FROM price_snapshots WHERE skinMarketHashName = :marketHashName " +
            "AND timestampMillis BETWEEN :fromMillis AND :toMillis ORDER BY timestampMillis ASC"
    )
    fun observeForSkin(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<PriceSnapshotEntity>>

    @Query("SELECT * FROM price_snapshots WHERE skinMarketHashName = :marketHashName ORDER BY timestampMillis DESC LIMIT 1")
    suspend fun latestForSkin(marketHashName: String): PriceSnapshotEntity?
}

@Dao
interface YoutubeMentionDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(mentions: List<YoutubeMentionEntity>)

    @Query(
        "SELECT * FROM youtube_mentions WHERE skinMarketHashName = :marketHashName " +
            "AND publishedAtMillis BETWEEN :fromMillis AND :toMillis ORDER BY viewCount DESC"
    )
    fun observeForSkin(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<YoutubeMentionEntity>>
}
