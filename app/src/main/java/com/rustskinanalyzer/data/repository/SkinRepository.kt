package com.rustskinanalyzer.data.repository

import com.rustskinanalyzer.data.local.PriceSnapshotDao
import com.rustskinanalyzer.data.local.PriceSnapshotEntity
import com.rustskinanalyzer.data.local.SkinDao
import com.rustskinanalyzer.data.local.SkinEntity
import com.rustskinanalyzer.data.model.PricePoint
import com.rustskinanalyzer.data.model.Skin
import com.rustskinanalyzer.data.remote.SteamMarketApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class SkinRepository(
    private val steamMarketApi: SteamMarketApi,
    private val skinDao: SkinDao,
    private val priceSnapshotDao: PriceSnapshotDao
) {
    fun observeTrackedSkins(): Flow<List<Skin>> =
        skinDao.observeAll().map { list ->
            list.map { Skin(it.marketHashName, it.displayName, it.weapon, it.iconUrl) }
        }

    suspend fun trackSkin(skin: Skin) {
        skinDao.upsert(
            SkinEntity(
                marketHashName = skin.marketHashName,
                displayName = skin.displayName,
                weapon = skin.weapon,
                iconUrl = skin.iconUrl,
                addedAtMillis = System.currentTimeMillis()
            )
        )
        // одразу тягнемо першу точку ціни, щоб список не був порожнім
        fetchAndStoreCurrentPrice(skin.marketHashName)
    }

    suspend fun untrackSkin(marketHashName: String) = skinDao.delete(marketHashName)

    /** Викликається як вручну (pull-to-refresh), так і з PriceUpdateWorker. */
    suspend fun fetchAndStoreCurrentPrice(marketHashName: String) {
        val dto = steamMarketApi.getPriceOverview(marketHashName = marketHashName)
        if (!dto.success) return
        priceSnapshotDao.insert(
            PriceSnapshotEntity(
                skinMarketHashName = marketHashName,
                timestampMillis = System.currentTimeMillis(),
                lowestPrice = dto.parseLowest(),
                medianPrice = dto.parseMedian(),
                volume = dto.parseVolume()
            )
        )
    }

    fun observePriceHistory(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<PricePoint>> =
        priceSnapshotDao.observeForSkin(marketHashName, fromMillis, toMillis).map { list ->
            list.map {
                PricePoint(it.skinMarketHashName, it.timestampMillis, it.lowestPrice, it.medianPrice, it.volume)
            }
        }
}
