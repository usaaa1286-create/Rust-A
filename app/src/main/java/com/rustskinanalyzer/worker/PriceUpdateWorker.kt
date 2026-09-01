package com.rustskinanalyzer.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.rustskinanalyzer.RustSkinApp
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first

/**
 * Проходить по всіх відстежуваних скінах і зберігає нову ціну.
 * Невелика затримка між запитами — щоб не впертися в рейт-ліміт Steam Market.
 */
class PriceUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val app = applicationContext as RustSkinApp
        return try {
            val skins = app.skinRepository.observeTrackedSkins().first()
            for (skin in skins) {
                app.skinRepository.fetchAndStoreCurrentPrice(skin.marketHashName)
                delay(3_000) // ~20 запитів/хв — безпечно для Steam
            }
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        const val UNIQUE_WORK_NAME = "price_update_worker"
    }
}
