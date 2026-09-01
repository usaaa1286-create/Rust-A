package com.rustskinanalyzer.ui

import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.rustskinanalyzer.data.model.Skin
import com.rustskinanalyzer.ui.home.HomeScreen
import com.rustskinanalyzer.ui.trend.TrendScreen
import com.rustskinanalyzer.ui.youtuber.YoutuberScreen
import java.net.URLDecoder
import java.net.URLEncoder

private const val ARG_MARKET_HASH_NAME = "marketHashName"
private const val ARG_WEAPON = "weapon"
private const val ARG_DISPLAY_NAME = "displayName"

@Composable
fun AppNavHost() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(onSkinClick = { skin ->
                navController.navigate(
                    "detail/${skin.marketHashName.encode()}/${skin.weapon.encode()}/${skin.displayName.encode()}"
                )
            })
        }
        composable(
            route = "detail/{$ARG_MARKET_HASH_NAME}/{$ARG_WEAPON}/{$ARG_DISPLAY_NAME}",
            arguments = listOf(
                navArgument(ARG_MARKET_HASH_NAME) { type = NavType.StringType },
                navArgument(ARG_WEAPON) { type = NavType.StringType },
                navArgument(ARG_DISPLAY_NAME) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val marketHashName = backStackEntry.arguments?.getString(ARG_MARKET_HASH_NAME)?.decode().orEmpty()
            val weapon = backStackEntry.arguments?.getString(ARG_WEAPON)?.decode().orEmpty()
            val displayName = backStackEntry.arguments?.getString(ARG_DISPLAY_NAME)?.decode().orEmpty()
            val skin = Skin(marketHashName, displayName, weapon)

            // Просто показуємо обидва блоки аналізу на одному екрані деталей.
            Column {
                TrendScreen(marketHashName = marketHashName)
                YoutuberScreen(skin = skin)
            }
        }
    }
}

private fun String.encode(): String = URLEncoder.encode(this, "UTF-8")
private fun String.decode(): String = URLDecoder.decode(this, "UTF-8")

@Composable
private fun Column(content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit) =
    androidx.compose.foundation.layout.Column(content = content)
