#!/usr/bin/env bash
set -e
# Перебудовує правильну структуру проєкту з нуля.
# Спершу приберемо все, крім .git, потім створимо файли заново.
find . -mindepth 1 -maxdepth 1 -not -name ".git" -exec rm -rf {} +

mkdir -p ".devcontainer"
cat > ".devcontainer/devcontainer.json" << 'RUSTSKIN_EOF'
{
  "name": "RustSkinAnalyzer Android Dev",
  "image": "mcr.microsoft.com/devcontainers/java:1-17-bullseye",
  "postCreateCommand": "bash .devcontainer/setup-android-sdk.sh",
  "remoteEnv": {
    "ANDROID_HOME": "/opt/android-sdk",
    "PATH": "${containerEnv:PATH}:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "vscjava.vscode-gradle",
        "redhat.vscode-yaml"
      ]
    }
  },
  "forwardPorts": []
}
RUSTSKIN_EOF

mkdir -p ".devcontainer"
cat > ".devcontainer/setup-android-sdk.sh" << 'RUSTSKIN_EOF'
#!/usr/bin/env bash
# Ставить мінімальний Android SDK (cmdline-tools + platform-tools + platform 34
# + build-tools 34.0.0), достатній для gradle assembleDebug.
set -e

SDK_ROOT="/opt/android-sdk"
sudo mkdir -p "$SDK_ROOT"
sudo chown -R "$(whoami)" "$SDK_ROOT"

cd /tmp
curl -sSL -o cmdline-tools.zip \
  "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
unzip -q cmdline-tools.zip -d "$SDK_ROOT/cmdline-tools-tmp"
mkdir -p "$SDK_ROOT/cmdline-tools"
mv "$SDK_ROOT/cmdline-tools-tmp/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
rm -rf "$SDK_ROOT/cmdline-tools-tmp" cmdline-tools.zip

export ANDROID_HOME="$SDK_ROOT"
export PATH="$PATH:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools"

yes | sdkmanager --licenses > /dev/null
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "Android SDK готовий. Тепер можна: cd RustSkinAnalyzer && gradle assembleDebug"
RUSTSKIN_EOF

mkdir -p ".github/workflows"
cat > ".github/workflows/build.yml" << 'RUSTSKIN_EOF'
name: Build debug APK

# Запускається автоматично при push у будь-яку гілку, і вручну через
# вкладку Actions -> Build debug APK -> Run workflow.
on:
  push:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3

      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: 8.7

      - name: Build debug APK
        run: gradle assembleDebug --stacktrace

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: RustSkinAnalyzer-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
RUSTSKIN_EOF

cat > "README.md" << 'RUSTSKIN_EOF'
# Rust Skin Analyzer (Android, Kotlin + Compose)

MVP-застосунок для аналізу популярності скінів Rust та їх використання ютюберами.

## Що вже є

- **Відстеження скінів**: додаєш зброю + назву скіну (`AK-47 | Redline` тощо).
- **Ціни/тренд**: фонова задача (`PriceUpdateWorker`, WorkManager) кожні 6 год опитує
  Steam Community Market і зберігає точку ціни в Room. З часом накопичується власна
  історія → графік тренду на екрані "Аналіз".
- **YouTube-аналіз**: пошук відео за YouTube Data API v3 за назвою зброї+скіну,
  фільтрація тих, де назва скіну справді є в заголовку/описі (`SkinNameMatcher`),
  агрегація кількості згадок і переглядів за період.

## Як зібрати без свого комп'ютера (все в браузері/телефоні)

### Варіант А — найпростіший: GitHub Actions збирає APK за тебе

1. Створи новий репозиторій на github.com (можна прямо з телефона в браузері).
2. Завантаж туди весь вміст цієї папки (`Add file → Upload files`, перетягни
   розпаковану папку цілком; на Chrome це працює навіть із телефона).
3. Відкрий вкладку **Actions** в репозиторії — workflow "Build debug APK"
   запуститься автоматично після завантаження файлів (є файл
   `.github/workflows/build.yml`).
4. Дочекайся зеленої галочки (~5-10 хв), відкрий завершений run → внизу розділ
   **Artifacts** → скачай `RustSkinAnalyzer-debug-apk`.
5. На телефоні розпакуй артефакт (це zip з одним `app-debug.apk`), відкрий
   `.apk`, дозволь встановлення з невідомих джерел — і застосунок встановиться.

Так можна робити після кожної зміни коду — просто пуш → почекати → скачати
новий APK. Ключ YouTube API до збірки додавати не обов'язково, застосунок
збереться, просто вкладка YouTube-аналізу не працюватиме без ключа.

### Варіант Б — редагувати код у браузері: GitHub Codespaces

1. У тому ж репозиторії на GitHub натисни зелену кнопку **Code → Codespaces →
   Create codespace on main**.
2. Дочекайся, поки підніметься контейнер (є `.devcontainer/devcontainer.json`,
   він сам поставить Android SDK через `setup-android-sdk.sh`, це займе кілька
   хвилин при першому запуску).
3. У вбудованому терміналі: `cd RustSkinAnalyzer && gradle assembleDebug`.
4. Готовий `.apk` буде в `app/build/outputs/apk/debug/app-debug.apk` — скачай
   через файловий провідник Codespaces (правий клік → Download).

Gitpod (gitpod.io) працює аналогічно — просто відкрий репозиторій за адресою
`gitpod.io/#https://github.com/<твій-акаунт>/<репо>`.

## Локальна збірка (Android Studio)

## Що треба зробити перед першим запуском

1. Відкрити проєкт в Android Studio (Koala/2024.1+), дати Gradle sync.
2. Отримати безкоштовний ключ **YouTube Data API v3**:
   console.cloud.google.com → створити проєкт → Enable API → Credentials → API key.
3. Вставити ключ у `gradle.properties`: `YOUTUBE_API_KEY=...`
4. Зібрати й запустити на емуляторі/пристрої (minSdk 26).

## Важливі технічні обмеження, про які варто знати

- **У Steam немає публічного API історії цін.** `/market/priceoverview/` дає лише
  ціну "зараз" і обсяг за сьогодні; `/market/pricehistory/` вимагає залогінену
  сесію власника предмета й для сторонніх акаунтів недоступний. Тому графік тренду
  будується з точок, які застосунок сам назбирав з часом — одразу після встановлення
  графік буде порожнім/коротким, це нормально.
- **Steam рейт-лімітить** запити без ключа (орієнтовно ~15-20/хв на IP). Воркер
  робить паузу 3с між скінами — при великій кількості відстежуваних скінів оновлення
  може займати кілька хвилин.
- **YouTube API квота**: 10 000 units/добу безкоштовно, `search.list` коштує 100
  units → ~100 пошукових запитів/добу. Тому пошук по конкретному скіну запускається
  вручну кнопкою, а не автоматично по всій базі.
- **Зіставлення "скін у відео" — евристика** (збіг ключових слів назви в заголовку
  й описі), а не аналіз відео/аудіо. Це дає прийнятну точність для назв на кшталт
  "AK-47 Redline", але не розпізнає скін візуально на кадрі — для цього знадобилась
  би окрема модель комп'ютерного зору, що вже вихід за межі MVP.
- Екран деталей зараз просто ставить TrendScreen і YoutuberScreen один під одним
  (спрощення для MVP) — варто винести їх у Tabs/Pager для кращого UX.

## Наступні кроки (не реалізовано)

- Порівняння кількох скінів між собою на одному графіку.
- Пуш-сповіщення про різкий стрибок ціни або сплеск згадок на YouTube.
- Альтернативні джерела даних (Skinport/BitSkins API) для ринкової глибини,
  якої немає в Steam.
RUSTSKIN_EOF

mkdir -p "app"
cat > "app/build.gradle.kts" << 'RUSTSKIN_EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.devtools.ksp")
}

android {
    namespace = "com.rustskinanalyzer"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.rustskinanalyzer"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"

        val youtubeKey = project.findProperty("YOUTUBE_API_KEY") as String? ?: ""
        buildConfigField("String", "YOUTUBE_API_KEY", "\"$youtubeKey\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.4")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.4")
    implementation("androidx.activity:activity-compose:1.9.1")

    val composeBom = platform("androidx.compose:compose-bom:2024.06.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-kotlinx-serialization:2.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")

    // Local storage
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // Background price polling (Steam gives no public history API — see README)
    implementation("androidx.work:work-runtime-ktx:2.9.1")

    debugImplementation("androidx.compose.ui:ui-tooling")
}
RUSTSKIN_EOF

mkdir -p "app/src/main"
cat > "app/src/main/AndroidManifest.xml" << 'RUSTSKIN_EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:label="Rust Skin Analyzer"
        android:theme="@style/Theme.RustSkinAnalyzer"
        android:name=".RustSkinApp">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.RustSkinAnalyzer">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer"
cat > "app/src/main/java/com/rustskinanalyzer/MainActivity.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.rustskinanalyzer.ui.AppNavHost
import com.rustskinanalyzer.ui.theme.RustSkinAnalyzerTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            RustSkinAnalyzerTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    AppNavHost()
                }
            }
        }
    }
}
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer"
cat > "app/src/main/java/com/rustskinanalyzer/RustSkinApp.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer

import android.app.Application
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.rustskinanalyzer.data.local.AppDatabase
import com.rustskinanalyzer.data.remote.NetworkModule
import com.rustskinanalyzer.data.repository.SkinRepository
import com.rustskinanalyzer.data.repository.YoutubeAnalysisRepository
import com.rustskinanalyzer.worker.PriceUpdateWorker
import java.util.concurrent.TimeUnit

class RustSkinApp : Application() {

    // Простий service locator замість Hilt/Koin — достатньо для розміру цього застосунку.
    lateinit var skinRepository: SkinRepository
        private set
    lateinit var youtubeAnalysisRepository: YoutubeAnalysisRepository
        private set

    override fun onCreate() {
        super.onCreate()
        val db = AppDatabase.getInstance(this)

        skinRepository = SkinRepository(
            steamMarketApi = NetworkModule.steamMarketApi,
            skinDao = db.skinDao(),
            priceSnapshotDao = db.priceSnapshotDao()
        )
        youtubeAnalysisRepository = YoutubeAnalysisRepository(
            youtubeApi = NetworkModule.youtubeApi,
            mentionDao = db.youtubeMentionDao()
        )

        schedulePriceUpdates()
    }

    private fun schedulePriceUpdates() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        // Кожні 6 годин: достатньо для тренду, не б'є по рейт-ліміту Steam.
        val request = PeriodicWorkRequestBuilder<PriceUpdateWorker>(6, TimeUnit.HOURS)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            PriceUpdateWorker.UNIQUE_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }
}
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/local"
cat > "app/src/main/java/com/rustskinanalyzer/data/local/AppDatabase.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [SkinEntity::class, PriceSnapshotEntity::class, YoutubeMentionEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun skinDao(): SkinDao
    abstract fun priceSnapshotDao(): PriceSnapshotDao
    abstract fun youtubeMentionDao(): YoutubeMentionDao

    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "rust_skin_analyzer.db"
                ).build().also { INSTANCE = it }
            }
    }
}
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/local"
cat > "app/src/main/java/com/rustskinanalyzer/data/local/Daos.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface SkinDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(skin: SkinEntity)

    @Query("DELETE FROM tracked_skins WHERE marketHashName = :marketHashName")
    suspend fun delete(marketHashName: String)

    @Query("SELECT * FROM tracked_skins ORDER BY addedAtMillis DESC")
    fun observeAll(): Flow<List<SkinEntity>>
}

@Dao
interface PriceSnapshotDao {
    @Insert
    suspend fun insert(snapshot: PriceSnapshotEntity)

    @Query(
        "SELECT * FROM price_snapshots WHERE skinMarketHashName = :marketHashName " +
            "AND timestampMillis BETWEEN :fromMillis AND :toMillis ORDER BY timestampMillis ASC"
    )
    fun observeForSkin(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<PriceSnapshotEntity>>

    @Query("SELECT * FROM price_snapshots WHERE skinMarketHashName = :marketHashName ORDER BY timestampMillis DESC LIMIT 1")
    suspend fun latestForSkin(marketHashName: String): PriceSnapshotEntity?
}

@Dao
interface YoutubeMentionDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(mentions: List<YoutubeMentionEntity>)

    @Query(
        "SELECT * FROM youtube_mentions WHERE skinMarketHashName = :marketHashName " +
            "AND publishedAtMillis BETWEEN :fromMillis AND :toMillis ORDER BY viewCount DESC"
    )
    fun observeForSkin(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<YoutubeMentionEntity>>
}
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/local"
cat > "app/src/main/java/com/rustskinanalyzer/data/local/Entities.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "tracked_skins")
data class SkinEntity(
    @PrimaryKey val marketHashName: String,
    val displayName: String,
    val weapon: String,
    val iconUrl: String? = null,
    val addedAtMillis: Long
)

@Entity(tableName = "price_snapshots")
data class PriceSnapshotEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val skinMarketHashName: String,
    val timestampMillis: Long,
    val lowestPrice: Double?,
    val medianPrice: Double?,
    val volume: Int?
)

@Entity(tableName = "youtube_mentions")
data class YoutubeMentionEntity(
    @PrimaryKey val videoId: String,
    val skinMarketHashName: String,
    val channelTitle: String,
    val videoTitle: String,
    val publishedAtMillis: Long,
    val viewCount: Long,
    val fetchedAtMillis: Long
)
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/model"
cat > "app/src/main/java/com/rustskinanalyzer/data/model/Models.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.data.model

/**
 * Скін, за яким користувач стежить.
 * marketHashName — точна назва предмета в Steam Market, напр. "AK-47 | Redline (Field-Tested)".
 * Для Rust предмети зазвичай мають вигляд "<Зброя> | <Назва скіну>".
 */
data class Skin(
    val marketHashName: String,
    val displayName: String,
    val weapon: String,
    val iconUrl: String? = null
)

/** Одна точка ціни, зібрана нашим застосунком у певний момент часу. */
data class PricePoint(
    val skinMarketHashName: String,
    val timestampMillis: Long,
    val lowestPrice: Double?,
    val medianPrice: Double?,
    val volume: Int?
)

/** Розрахований тренд для скіну за період. */
data class SkinTrend(
    val skinMarketHashName: String,
    val points: List<PricePoint>,
    val changePercent: Double?,
    val direction: TrendDirection
)

enum class TrendDirection { UP, DOWN, FLAT, UNKNOWN }

/** Відео на YouTube, у якому, ймовірно, згадується/показується скін. */
data class YoutuberMention(
    val videoId: String,
    val channelTitle: String,
    val videoTitle: String,
    val publishedAtMillis: Long,
    val viewCount: Long,
    val matchedSkinMarketHashName: String
)

/** Агреговані дані про використання скіну ютюберами за період. */
data class YoutuberUsageSummary(
    val skinMarketHashName: String,
    val periodStartMillis: Long,
    val periodEndMillis: Long,
    val mentionCount: Int,
    val totalViews: Long,
    val topChannels: List<String>
)
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/remote"
cat > "app/src/main/java/com/rustskinanalyzer/data/remote/NetworkModule.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/remote"
cat > "app/src/main/java/com/rustskinanalyzer/data/remote/SteamMarketApi.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/remote"
cat > "app/src/main/java/com/rustskinanalyzer/data/remote/YoutubeApi.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.data.remote

import kotlinx.serialization.Serializable
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * YouTube Data API v3. Потрібен безкоштовний ключ з Google Cloud Console
 * (увімкнути "YouTube Data API v3"). Квота за замовчуванням: 10 000 "units"/день;
 * search.list коштує 100 units за запит — тобто ~100 пошуків/добу безкоштовно.
 * Тому в MVP шукаємо по одному скіну за раз, а не масово по всій базі щоразу.
 */
interface YoutubeApi {
    @GET("search")
    suspend fun searchVideos(
        @Query("q") query: String,
        @Query("part") part: String = "snippet",
        @Query("type") type: String = "video",
        @Query("order") order: String = "relevance",
        @Query("publishedAfter") publishedAfterIso: String,
        @Query("publishedBefore") publishedBeforeIso: String,
        @Query("maxResults") maxResults: Int = 25,
        @Query("regionCode") regionCode: String = "US",
        @Query("key") apiKey: String
    ): YoutubeSearchResponseDto

    /** Другий виклик потрібен, бо search.list не повертає статистику переглядів. */
    @GET("videos")
    suspend fun getVideoStatistics(
        @Query("id") commaSeparatedVideoIds: String,
        @Query("part") part: String = "statistics,snippet",
        @Query("key") apiKey: String
    ): YoutubeVideosResponseDto

    companion object {
        const val BASE_URL = "https://www.googleapis.com/youtube/v3/"
    }
}

@Serializable
data class YoutubeSearchResponseDto(
    val items: List<YoutubeSearchItemDto> = emptyList()
)

@Serializable
data class YoutubeSearchItemDto(
    val id: YoutubeVideoIdDto,
    val snippet: YoutubeSnippetDto
)

@Serializable
data class YoutubeVideoIdDto(val videoId: String? = null)

@Serializable
data class YoutubeSnippetDto(
    val title: String,
    val description: String,
    val channelTitle: String,
    val publishedAt: String
)

@Serializable
data class YoutubeVideosResponseDto(
    val items: List<YoutubeVideoItemDto> = emptyList()
)

@Serializable
data class YoutubeVideoItemDto(
    val id: String,
    val snippet: YoutubeSnippetDto,
    val statistics: YoutubeStatisticsDto? = null
)

@Serializable
data class YoutubeStatisticsDto(
    val viewCount: String? = null
)
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/repository"
cat > "app/src/main/java/com/rustskinanalyzer/data/repository/SkinRepository.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.data.repository

import com.rustskinanalyzer.data.local.PriceSnapshotDao
import com.rustskinanalyzer.data.local.PriceSnapshotEntity
import com.rustskinanalyzer.data.local.SkinDao
import com.rustskinanalyzer.data.local.SkinEntity
import com.rustskinanalyzer.data.model.PricePoint
import com.rustskinanalyzer.data.model.Skin
import com.rustskinanalyzer.data.remote.SteamMarketApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class SkinRepository(
    private val steamMarketApi: SteamMarketApi,
    private val skinDao: SkinDao,
    private val priceSnapshotDao: PriceSnapshotDao
) {
    fun observeTrackedSkins(): Flow<List<Skin>> =
        skinDao.observeAll().map { list ->
            list.map { Skin(it.marketHashName, it.displayName, it.weapon, it.iconUrl) }
        }

    suspend fun trackSkin(skin: Skin) {
        skinDao.upsert(
            SkinEntity(
                marketHashName = skin.marketHashName,
                displayName = skin.displayName,
                weapon = skin.weapon,
                iconUrl = skin.iconUrl,
                addedAtMillis = System.currentTimeMillis()
            )
        )
        // одразу тягнемо першу точку ціни, щоб список не був порожнім
        fetchAndStoreCurrentPrice(skin.marketHashName)
    }

    suspend fun untrackSkin(marketHashName: String) = skinDao.delete(marketHashName)

    /** Викликається як вручну (pull-to-refresh), так і з PriceUpdateWorker. */
    suspend fun fetchAndStoreCurrentPrice(marketHashName: String) {
        val dto = steamMarketApi.getPriceOverview(marketHashName = marketHashName)
        if (!dto.success) return
        priceSnapshotDao.insert(
            PriceSnapshotEntity(
                skinMarketHashName = marketHashName,
                timestampMillis = System.currentTimeMillis(),
                lowestPrice = dto.parseLowest(),
                medianPrice = dto.parseMedian(),
                volume = dto.parseVolume()
            )
        )
    }

    fun observePriceHistory(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<PricePoint>> =
        priceSnapshotDao.observeForSkin(marketHashName, fromMillis, toMillis).map { list ->
            list.map {
                PricePoint(it.skinMarketHashName, it.timestampMillis, it.lowestPrice, it.medianPrice, it.volume)
            }
        }
}
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/data/repository"
cat > "app/src/main/java/com/rustskinanalyzer/data/repository/YoutubeAnalysisRepository.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.data.repository

import com.rustskinanalyzer.BuildConfig
import com.rustskinanalyzer.data.local.YoutubeMentionDao
import com.rustskinanalyzer.data.local.YoutubeMentionEntity
import com.rustskinanalyzer.data.model.Skin
import com.rustskinanalyzer.data.model.YoutuberMention
import com.rustskinanalyzer.data.model.YoutuberUsageSummary
import com.rustskinanalyzer.data.remote.YoutubeApi
import com.rustskinanalyzer.domain.SkinNameMatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.format.DateTimeFormatter

class YoutubeAnalysisRepository(
    private val youtubeApi: YoutubeApi,
    private val mentionDao: YoutubeMentionDao
) {
    /**
     * Шукає відео за період [fromMillis, toMillis], фільтрує ті, де реально
     * згадується назва скіну (а не лише слово з запиту), тягне статистику
     * переглядів і кешує результат локально.
     */
    suspend fun refreshMentionsForSkin(skin: Skin, fromMillis: Long, toMillis: Long) {
        val query = SkinNameMatcher.buildSearchQuery(skin.weapon, skin.displayName)
        val searchResponse = youtubeApi.searchVideos(
            q = query,
            publishedAfterIso = toIso(fromMillis),
            publishedBeforeIso = toIso(toMillis),
            apiKey = BuildConfig.YOUTUBE_API_KEY
        )

        val candidateIds = searchResponse.items.mapNotNull { it.id.videoId }
        if (candidateIds.isEmpty()) return

        val statsResponse = youtubeApi.getVideoStatistics(
            commaSeparatedVideoIds = candidateIds.joinToString(","),
            apiKey = BuildConfig.YOUTUBE_API_KEY
        )

        val matched = statsResponse.items.filter { video ->
            SkinNameMatcher.isMentioned(skin.displayName, video.snippet.title + " " + video.snippet.description)
        }

        val entities = matched.map { video ->
            YoutubeMentionEntity(
                videoId = video.id,
                skinMarketHashName = skin.marketHashName,
                channelTitle = video.snippet.channelTitle,
                videoTitle = video.snippet.title,
                publishedAtMillis = Instant.parse(video.snippet.publishedAt).toEpochMilli(),
                viewCount = video.statistics?.viewCount?.toLongOrNull() ?: 0L,
                fetchedAtMillis = System.currentTimeMillis()
            )
        }
        mentionDao.insertAll(entities)
    }

    fun observeMentions(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<List<YoutuberMention>> =
        mentionDao.observeForSkin(marketHashName, fromMillis, toMillis).map { list ->
            list.map {
                YoutuberMention(it.videoId, it.channelTitle, it.videoTitle, it.publishedAtMillis, it.viewCount, it.skinMarketHashName)
            }
        }

    fun observeUsageSummary(marketHashName: String, fromMillis: Long, toMillis: Long): Flow<YoutuberUsageSummary> =
        observeMentions(marketHashName, fromMillis, toMillis).map { mentions ->
            YoutuberUsageSummary(
                skinMarketHashName = marketHashName,
                periodStartMillis = fromMillis,
                periodEndMillis = toMillis,
                mentionCount = mentions.size,
                totalViews = mentions.sumOf { it.viewCount },
                topChannels = mentions.groupBy { it.channelTitle }
                    .toList()
                    .sortedByDescending { (_, vids) -> vids.sumOf { it.viewCount } }
                    .take(5)
                    .map { it.first }
            )
        }

    private fun toIso(millis: Long): String =
        DateTimeFormatter.ISO_INSTANT.format(Instant.ofEpochMilli(millis))
}
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/domain"
cat > "app/src/main/java/com/rustskinanalyzer/domain/SkinNameMatcher.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.domain

/**
 * Проста, але надійна перевірка "чи згадується цей скін у тексті відео".
 * MVP-підхід: нормалізуємо обидва рядки (нижній регістр, без пунктуації) і
 * перевіряємо, чи всі значущі слова назви скіну присутні в тексті.
 * Це навмисно простіше за ML/NLP-рішення — легко пояснити хибні спрацювання
 * і легко покращувати список стоп-слів вручну.
 */
object SkinNameMatcher {

    private val stopWords = setOf("the", "a", "an", "rust", "skin", "|")

    fun normalize(text: String): List<String> =
        text.lowercase()
            .replace(Regex("[^a-z0-9\\s|]"), " ")
            .split(Regex("\\s+"))
            .filter { it.isNotBlank() && it !in stopWords }

    /**
     * @param skinDisplayName напр. "AK-47 | Redline" (без стану зношеності)
     * @param text заголовок + опис відео
     */
    fun isMentioned(skinDisplayName: String, text: String): Boolean {
        val skinTokens = normalize(skinDisplayName)
        if (skinTokens.isEmpty()) return false
        val textTokens = normalize(text).toSet()
        // вимагаємо збіг щонайменше 80% значущих слів назви скіну (округлення вгору)
        val required = ((skinTokens.size * 0.8).toInt()).coerceAtLeast(skinTokens.size - 1).coerceAtLeast(1)
        val matched = skinTokens.count { it in textTokens }
        return matched >= required
    }

    /** Формує пошуковий запит для YouTube Data API. */
    fun buildSearchQuery(weapon: String, skinDisplayName: String): String =
        "rust $weapon $skinDisplayName skin"
}
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/domain"
cat > "app/src/main/java/com/rustskinanalyzer/domain/TrendAnalyzer.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/ui"
cat > "app/src/main/java/com/rustskinanalyzer/ui/Navigation.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/ui/components"
cat > "app/src/main/java/com/rustskinanalyzer/ui/components/PriceChart.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/ui/home"
cat > "app/src/main/java/com/rustskinanalyzer/ui/home/HomeScreen.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/ui/home"
cat > "app/src/main/java/com/rustskinanalyzer/ui/home/HomeViewModel.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/ui/theme"
cat > "app/src/main/java/com/rustskinanalyzer/ui/theme/Theme.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/ui/trend"
cat > "app/src/main/java/com/rustskinanalyzer/ui/trend/TrendScreen.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/ui/youtuber"
cat > "app/src/main/java/com/rustskinanalyzer/ui/youtuber/YoutuberScreen.kt" << 'RUSTSKIN_EOF'
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
RUSTSKIN_EOF

mkdir -p "app/src/main/java/com/rustskinanalyzer/worker"
cat > "app/src/main/java/com/rustskinanalyzer/worker/PriceUpdateWorker.kt" << 'RUSTSKIN_EOF'
package com.rustskinanalyzer.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.rustskinanalyzer.RustSkinApp
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first

/**
 * Проходить по всіх відстежуваних скінах і зберігає нову ціну.
 * Невелика затримка між запитами — щоб не впертися в рейт-ліміт Steam Market.
 */
class PriceUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val app = applicationContext as RustSkinApp
        return try {
            val skins = app.skinRepository.observeTrackedSkins().first()
            for (skin in skins) {
                app.skinRepository.fetchAndStoreCurrentPrice(skin.marketHashName)
                delay(3_000) // ~20 запитів/хв — безпечно для Steam
            }
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        const val UNIQUE_WORK_NAME = "price_update_worker"
    }
}
RUSTSKIN_EOF

mkdir -p "app/src/main/res/drawable"
cat > "app/src/main/res/drawable/ic_launcher_background.xml" << 'RUSTSKIN_EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#2B2621"
        android:pathData="M0,0h108v108h-108z" />
</vector>
RUSTSKIN_EOF

mkdir -p "app/src/main/res/drawable"
cat > "app/src/main/res/drawable/ic_launcher_foreground.xml" << 'RUSTSKIN_EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- diamond = "skin" item -->
    <path
        android:fillColor="#CE7C3E"
        android:pathData="M54,26 L78,54 L54,82 L30,54 Z" />
    <!-- magnifying glass ring -->
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="6"
        android:fillColor="#00000000"
        android:pathData="M62,46 m-13,0 a13,13 0 1,0 26,0 a13,13 0 1,0 -26,0" />
    <!-- magnifying glass handle -->
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="6"
        android:strokeLineCap="round"
        android:pathData="M72,56 L82,66" />
</vector>
RUSTSKIN_EOF

mkdir -p "app/src/main/res/mipmap-anydpi-v26"
cat > "app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml" << 'RUSTSKIN_EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
RUSTSKIN_EOF

mkdir -p "app/src/main/res/mipmap-anydpi-v26"
cat > "app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml" << 'RUSTSKIN_EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
RUSTSKIN_EOF

mkdir -p "app/src/main/res/values"
cat > "app/src/main/res/values/themes.xml" << 'RUSTSKIN_EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.RustSkinAnalyzer" parent="android:Theme.Material.Light.NoActionBar" />
</resources>
RUSTSKIN_EOF

cat > "build.gradle.kts" << 'RUSTSKIN_EOF'
plugins {
    id("com.android.application") version "8.5.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.24" apply false
    id("com.google.devtools.ksp") version "1.9.24-1.0.20" apply false
}
RUSTSKIN_EOF

cat > "gradle.properties" << 'RUSTSKIN_EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official

# TODO: отримайте безкоштовний ключ на https://console.cloud.google.com/apis/credentials
# (увімкніть "YouTube Data API v3") і вставте його сюди.
YOUTUBE_API_KEY=PUT_YOUR_YOUTUBE_API_KEY_HERE
RUSTSKIN_EOF

cat > "settings.gradle.kts" << 'RUSTSKIN_EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "RustSkinAnalyzer"
include(":app")
RUSTSKIN_EOF

chmod +x .devcontainer/setup-android-sdk.sh
git add -A
git commit -m "Fix project structure"
git push
echo "Готово! Структуру відновлено і запушено."
