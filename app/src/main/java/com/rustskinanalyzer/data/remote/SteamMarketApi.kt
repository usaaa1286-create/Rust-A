package com.rustskinanalyzer.data.remote

import kotlinx.serialization.Serializable
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * Steam Community Market — публічний, безкоштовний ендпоінт, ключ не потрібен.
 *
 * ВАЖЛИВО: /market/priceoverview/ віддає лише ПОТОЧНУ ціну (lowest/median) та обсяг
 * продажів ЗА СЬОГОДНІ. Офіційного публічного API для історії цін немає —
 * /market/pricehistory/ вимагає залогінену сесію власника предмета і для чужих
 * акаунтів не працює. Тому тренд ми будуємо самі: PriceUpdateWorker періодично
 * опитує priceoverview і зберігає точки в Room — з часом накопичується власна історія.
 *
 * App ID Rust = 252490. Дотримуйтесь пауз між запитами (Steam агресивно рейт-лімітить,
 * орієнтовно ~15-20 запитів/хв на IP), інакше отримаєте HTTP 429.
 */
interface SteamMarketApi {
    @GET("market/priceoverview/")
    suspend fun getPriceOverview(
        @Query("appid") appId: Int = RUST_APP_ID,
        @Query("currency") currency: Int = 1, // 1 = USD
        @Query("market_hash_name") marketHashName: String
    ): PriceOverviewDto

    companion object {
        const val RUST_APP_ID = 252490
        const val BASE_URL = "https://steamcommunity.com/"
    }
}

@Serializable
data class PriceOverviewDto(
    val success: Boolean = false,
    val lowest_price: String? = null,
    val median_price: String? = null,
    val volume: String? = null
) {
    fun parseLowest(): Double? = lowest_price?.parsePrice()
    fun parseMedian(): Double? = median_price?.parsePrice()
    fun parseVolume(): Int? = volume?.replace(",", "")?.toIntOrNull()
}

/** "$1,234.56" -> 1234.56 (валюта Steam приходить у різних форматах залежно від локалі) */
private fun String.parsePrice(): Double? =
    this.replace(Regex("[^0-9.,]"), "")
        .replace(",", ".")
        .let { cleaned ->
            // якщо після заміни лишилось дві крапки (тис. роздільник + десятковий) — беремо останню
            val lastDot = cleaned.lastIndexOf('.')
            if (cleaned.count { it == '.' } > 1 && lastDot != -1) {
                (cleaned.substring(0, lastDot).replace(".", "") + cleaned.substring(lastDot))
                    .toDoubleOrNull()
            } else {
                cleaned.toDoubleOrNull()
            }
        }
