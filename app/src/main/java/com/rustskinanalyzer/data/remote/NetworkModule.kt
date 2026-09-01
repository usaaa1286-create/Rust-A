package com.rustskinanalyzer.data.remote

import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import java.util.concurrent.TimeUnit

object NetworkModule {

    private val json = Json { ignoreUnknownKeys = true }

    private fun okHttpClient(): OkHttpClient =
        OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC })
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .build()

    val steamMarketApi: SteamMarketApi by lazy {
        Retrofit.Builder()
            .baseUrl(SteamMarketApi.BASE_URL)
            .client(okHttpClient())
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
            .create(SteamMarketApi::class.java)
    }

    val youtubeApi: YoutubeApi by lazy {
        Retrofit.Builder()
            .baseUrl(YoutubeApi.BASE_URL)
            .client(okHttpClient())
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
            .create(YoutubeApi::class.java)
    }
}
