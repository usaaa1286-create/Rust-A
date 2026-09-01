package com.rustskinanalyzer.ui.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.rustskinanalyzer.RustSkinApp
import com.rustskinanalyzer.data.model.Skin
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class HomeViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = (application as RustSkinApp).skinRepository

    val skins: StateFlow<List<Skin>> = repository.observeTrackedSkins()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun addSkin(weapon: String, skinName: String) {
        viewModelScope.launch {
            val marketHashName = "$weapon | $skinName"
            repository.trackSkin(
                Skin(
                    marketHashName = marketHashName,
                    displayName = skinName,
                    weapon = weapon
                )
            )
        }
    }
}
