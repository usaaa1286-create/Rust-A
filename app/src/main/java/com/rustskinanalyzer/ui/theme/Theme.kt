package com.rustskinanalyzer.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val RustOrange = Color(0xFFCE7C3E)
private val RustDark = Color(0xFF2B2621)

private val DarkColors = darkColorScheme(
    primary = RustOrange,
    background = RustDark,
    surface = RustDark
)

private val LightColors = lightColorScheme(
    primary = RustOrange
)

@Composable
fun RustSkinAnalyzerTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) DarkColors else LightColors
    MaterialTheme(colorScheme = colors, content = content)
}
