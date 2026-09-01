package com.rustskinanalyzer.ui.youtuber

import android.app.Application
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rustskinanalyzer.RustSkinApp
import com.rustskinanalyzer.data.model.Skin
import com.rustskinanalyzer.data.model.YoutuberMention
import com.rustskinanalyzer.data.model.YoutuberUsageSummary
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

class YoutuberViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = (application as RustSkinApp).youtubeAnalysisRepository

    fun mentionsFor(skin: Skin, days: Long = 30): StateFlow<List<YoutuberMention>> {
        val (from, to) = period(days)
        return repository.observeMentions(skin.marketHashName, from, to)
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    }

    fun summaryFor(skin: Skin, days: Long = 30): StateFlow<YoutuberUsageSummary?> {
        val (from, to) = period(days)
        return repository.observeUsageSummary(skin.marketHashName, from, to)
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)
    }

    fun refresh(skin: Skin, days: Long = 30) {
        val (from, to) = period(days)
        viewModelScope.launch { repository.refreshMentionsForSkin(skin, from, to) }
    }

    private fun period(days: Long): Pair<Long, Long> {
        val to = System.currentTimeMillis()
        val from = to - TimeUnit.DAYS.toMillis(days)
        return from to to
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun YoutuberScreen(
    skin: Skin,
    viewModel: YoutuberViewModel = viewModel()
) {
    val mentions by viewModel.mentionsFor(skin).collectAsStateWithLifecycle()
    val summary by viewModel.summaryFor(skin).collectAsStateWithLifecycle()

    Scaffold(topBar = { TopAppBar(title = { Text("YouTube: ${skin.displayName}") }) }) { padding ->
        Column(modifier = Modifier.padding(padding).padding(16.dp)) {
            Text(
                "Пошук відео за 30 днів, де назва скіну згадується в заголовку " +
                    "чи описі. Потребує дійсного ключа YouTube Data API v3 в gradle.properties."
            )
            Button(
                onClick = { viewModel.refresh(skin) },
                modifier = Modifier.padding(vertical = 8.dp)
            ) { Text("Шукати згадки на YouTube") }

            summary?.let { s ->
                Text("Всього відео: ${s.mentionCount}, сумарні перегляди: ${s.totalViews}")
                if (s.topChannels.isNotEmpty()) {
                    Text("Топ канали: ${s.topChannels.joinToString(", ")}")
                }
            }

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(top = 12.dp)
            ) {
                items(mentions) { mention ->
                    Card(modifier = Modifier.fillMaxWidth().padding(4.dp)) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Text(mention.videoTitle)
                            Text(mention.channelTitle)
                            Text("Перегляди: ${mention.viewCount}")
                        }
                    }
                }
            }
        }
    }
}
