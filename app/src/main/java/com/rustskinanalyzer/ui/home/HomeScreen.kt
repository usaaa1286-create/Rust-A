package com.rustskinanalyzer.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rustskinanalyzer.data.model.Skin

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: HomeViewModel = viewModel(),
    onSkinClick: (Skin) -> Unit
) {
    val skins by viewModel.skins.collectAsStateWithLifecycle()
    var weaponInput by remember { mutableStateOf("") }
    var skinNameInput by remember { mutableStateOf("") }

    Scaffold(topBar = { TopAppBar(title = { Text("Rust Skin Analyzer") }) }) { padding ->
        Column(modifier = Modifier.padding(padding).padding(16.dp)) {
            Text("Додати скін для відстеження")
            OutlinedTextField(
                value = weaponInput,
                onValueChange = { weaponInput = it },
                label = { Text("Зброя, напр. AK-47") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = skinNameInput,
                onValueChange = { skinNameInput = it },
                label = { Text("Назва скіну, напр. Redline") },
                modifier = Modifier.fillMaxWidth()
            )
            Button(
                onClick = {
                    if (weaponInput.isNotBlank() && skinNameInput.isNotBlank()) {
                        viewModel.addSkin(weaponInput.trim(), skinNameInput.trim())
                        weaponInput = ""
                        skinNameInput = ""
                    }
                },
                modifier = Modifier.padding(top = 8.dp)
            ) { Text("Додати") }

            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(top = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(bottom = 16.dp)
            ) {
                items(skins) { skin ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(
                            modifier = Modifier
                                .padding(12.dp)
                                .fillMaxWidth()
                        ) {
                            Text(skin.displayName)
                            Button(onClick = { onSkinClick(skin) }) {
                                Text("Аналіз")
                            }
                        }
                    }
                }
            }
        }
    }
}
