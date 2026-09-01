package com.rustskinanalyzer

import android.app.Application
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.rustskinanalyzer.data.local.AppDatabase
import com.rustskinanalyzer.data.remote.NetworkModule
import com.rustskinanalyzer.data.repository.SkinRepository
import com.rustskinanalyzer.data.repository.YoutubeAnalysisRepository
import com.rustskinanalyzer.worker.PriceUpdateWorker
import java.util.concurrent.TimeUnit

class RustSkinApp : Application() {

    // Простий service locator замість Hilt/Koin — достатньо для розміру цього застосунку.
    lateinit var skinRepository: SkinRepository
        private set
    lateinit var youtubeAnalysisRepository: YoutubeAnalysisRepository
        private set

    override fun onCreate() {
        super.onCreate()
        val db = AppDatabase.getInstance(this)

        skinRepository = SkinRepository(
            steamMarketApi = NetworkModule.steamMarketApi,
            skinDao = db.skinDao(),
            priceSnapshotDao = db.priceSnapshotDao()
        )
        youtubeAnalysisRepository = YoutubeAnalysisRepository(
            youtubeApi = NetworkModule.youtubeApi,
            mentionDao = db.youtubeMentionDao()
        )

        schedulePriceUpdates()
    }

    private fun schedulePriceUpdates() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        // Кожні 6 годин: достатньо для тренду, не б'є по рейт-ліміту Steam.
        val request = PeriodicWorkRequestBuilder<PriceUpdateWorker>(6, TimeUnit.HOURS)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            PriceUpdateWorker.UNIQUE_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }
}
