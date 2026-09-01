package com.rustskinanalyzer.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.unit.dp
import com.rustskinanalyzer.data.model.PricePoint

/**
 * Легкий власний лінійний графік — без зайвої залежності на charting-бібліотеку.
 * Для складніших візуалізацій (свічки, зум) можна замінити на бібліотеку Vico.
 */
@Composable
fun PriceChart(points: List<PricePoint>, modifier: Modifier = Modifier) {
    val prices = points.mapNotNull { it.medianPrice ?: it.lowestPrice }
    if (prices.size < 2) return

    val lineColor = MaterialTheme.colorScheme.primary
    val min = prices.min()
    val max = prices.max()
    val range = (max - min).takeIf { it > 0 } ?: 1.0

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp)
    ) {
        val stepX = size.width / (prices.size - 1)
        val path = prices.mapIndexed { index, price ->
            val x = index * stepX
            val y = size.height - ((price - min) / range * size.height).toFloat()
            Offset(x, y)
        }
        for (i in 0 until path.size - 1) {
            drawLine(
                color = lineColor,
                start = path[i],
                end = path[i + 1],
                strokeWidth = 4f
            )
        }
    }
}
