package com.rustskinanalyzer.ui.trend

import android.app.Application
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rustskinanalyzer.RustSkinApp
import com.rustskinanalyzer.data.model.SkinTrend
import com.rustskinanalyzer.data.model.TrendDirection
import com.rustskinanalyzer.domain.TrendAnalyzer
import com.rustskinanalyzer.ui.components.PriceChart
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

class TrendViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = (application as RustSkinApp).skinRepository

    fun trendFor(marketHashName: String, days: Long = 30): StateFlow<SkinTrend?> {
        val from = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(days)
        val to = System.currentTimeMillis()
        return repository.observePriceHistory(marketHashName, from, to)
            .map { points -> if (points.isEmpty()) null else TrendAnalyzer.analyze(marketHashName, points) }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)
    }

    fun refreshNow(marketHashName: String) {
        viewModelScope.launch { repository.fetchAndStoreCurrentPrice(marketHashName) }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrendScreen(
    marketHashName: String,
    viewModel: TrendViewModel = viewModel()
) {
    val trend by viewModel.trendFor(marketHashName).collectAsStateWithLifecycle()

    LaunchedEffect(marketHashName) { viewModel.refreshNow(marketHashName) }

    Scaffold(topBar = { TopAppBar(title = { Text(marketHashName) }) }) { padding ->
        Column(modifier = Modifier.padding(padding).padding(16.dp)) {
            val t = trend
            if (t == null) {
                Text(
                    "Ще недостатньо даних для тренду. Дані про ціни накопичуються " +
                        "з кожним фоновим оновленням (Steam не дає готової історії — " +
                        "див. README). Спробуйте оновити зараз або зачекайте."
                )
            } else {
                val directionText = when (t.direction) {
                    TrendDirection.UP -> "Зростає"
                    TrendDirection.DOWN -> "Спадає"
                    TrendDirection.FLAT -> "Стабільно"
                    TrendDirection.UNKNOWN -> "Недостатньо даних"
                }
                Text("Тренд за 30 днів: $directionText")
                t.changePercent?.let { Text("Зміна: %.2f%%".format(it)) }
                PriceChart(points = t.points, modifier = Modifier.padding(top = 16.dp))
            }
            Button(
                onClick = { viewModel.refreshNow(marketHashName) },
                modifier = Modifier.padding(top = 16.dp)
            ) { Text("Оновити ціну зараз") }
        }
    }
}
