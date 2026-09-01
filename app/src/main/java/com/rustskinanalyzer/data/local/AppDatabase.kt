package com.rustskinanalyzer.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [SkinEntity::class, PriceSnapshotEntity::class, YoutubeMentionEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun skinDao(): SkinDao
    abstract fun priceSnapshotDao(): PriceSnapshotDao
    abstract fun youtubeMentionDao(): YoutubeMentionDao

    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "rust_skin_analyzer.db"
                ).build().also { INSTANCE = it }
            }
    }
}
