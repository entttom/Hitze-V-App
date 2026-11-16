package org.entner.HitzeV

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.entner.HitzeV.push.EXTRA_GKZ
import org.entner.HitzeV.ui.HitzeVApp
import org.entner.HitzeV.ui.theme.HitzeVTheme
import org.entner.HitzeV.ui.theme.isDark

// AppCompatActivity so AppCompatDelegate.setApplicationLocales also works below API 33.
class MainActivity : AppCompatActivity() {
    private val viewModel: DashboardViewModel by viewModels { DashboardViewModel.Factory }

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        super.onCreate(savedInstanceState)
        splashScreen.setKeepOnScreenCondition { !viewModel.uiState.value.preferencesLoaded }
        if (savedInstanceState == null) {
            handleNotificationIntent(intent)
        }

        setContent {
            val state by viewModel.uiState.collectAsStateWithLifecycle()
            val darkTheme = state.appTheme.isDark()

            DisposableEffect(darkTheme) {
                // Bar icons follow the in-app theme, not the system one, so they stay visible.
                enableEdgeToEdge(
                    statusBarStyle = SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { darkTheme },
                    navigationBarStyle = SystemBarStyle.auto(LightNavigationScrim, DarkNavigationScrim) { darkTheme }
                )
                onDispose { }
            }

            HitzeVTheme(darkTheme = darkTheme) {
                Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    HitzeVApp(viewModel = viewModel)
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        val gkz = intent?.getStringExtra(EXTRA_GKZ)?.takeIf { it.isNotBlank() } ?: return
        viewModel.onNotificationOpened(gkz)
        intent.removeExtra(EXTRA_GKZ)
    }

    private companion object {
        // Same scrims androidx.activity uses for 3-button navigation.
        val LightNavigationScrim = Color.argb(0xe6, 0xFF, 0xFF, 0xFF)
        val DarkNavigationScrim = Color.argb(0x80, 0x1b, 0x1b, 0x1b)
    }
}
