package com.rustskinanalyzer.domain

import com.rustskinanalyzer.data.model.PricePoint
import com.rustskinanalyzer.data.model.SkinTrend
import com.rustskinanalyzer.data.model.TrendDirection
import kotlin.math.abs

object TrendAnalyzer {

    private const val FLAT_THRESHOLD_PERCENT = 1.0

    fun analyze(skinMarketHashName: String, points: List<PricePoint>): SkinTrend {
        val sorted = points.sortedBy { it.timestampMillis }
        val first = sorted.firstOrNull()?.medianPrice ?: sorted.firstOrNull()?.lowestPrice
        val last = sorted.lastOrNull()?.medianPrice ?: sorted.lastOrNull()?.lowestPrice

        val changePercent = if (first != null && last != null && first != 0.0) {
            ((last - first) / first) * 100
        } else null

        val direction = when {
            changePercent == null -> TrendDirection.UNKNOWN
            abs(changePercent) < FLAT_THRESHOLD_PERCENT -> TrendDirection.FLAT
            changePercent > 0 -> TrendDirection.UP
            else -> TrendDirection.DOWN
        }

        return SkinTrend(
            skinMarketHashName = skinMarketHashName,
            points = sorted,
            changePercent = changePercent,
            direction = direction
        )
    }

    /** Рейтинг "популярності" за обсягом продажів для сортування списку скінів. */
    fun popularityScore(points: List<PricePoint>): Double =
        points.sumOf { (it.volume ?: 0).toDouble() }
}
