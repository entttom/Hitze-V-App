package org.entner.HitzeV.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import org.entner.HitzeV.ui.components.HeroBrush
import org.entner.HitzeV.ui.components.HitzeVPreviews
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.PreviewSurface
import org.entner.HitzeV.ui.components.readableWidth

/**
 * Notification pre-prompt. Its only action is the neutral "Continue", which immediately triggers
 * the system permission dialog (API 33+); there is deliberately no skip/later option on this step.
 *
 * @param showWelcome false for restored setups that only need the notification explainer.
 */
@Composable
fun OnboardingScreen(showWelcome: Boolean, onContinue: () -> Unit) {
    val copy = LocalCopybook.current

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(HeroBrush),
        contentAlignment = Alignment.TopCenter
    ) {
        Column(
            modifier = Modifier
                .readableWidth()
                .fillMaxHeight()
                // Insets before the scroll so scrolled text never runs under the status bar.
                .windowInsetsPadding(WindowInsets.safeDrawing)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            if (showWelcome) {
                Icon(
                    imageVector = Icons.Rounded.WbSunny,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(72.dp)
                )
                Text(
                    copy.onboardingWelcomeTitle,
                    style = MaterialTheme.typography.displayMedium,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.semantics { heading() }
                )
                Text(
                    copy.onboardingWelcomeText,
                    style = MaterialTheme.typography.bodyLarge,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )
            }

            Surface(
                shape = RoundedCornerShape(24.dp),
                color = Color.Black.copy(alpha = 0.28f),
                contentColor = Color.White
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(Icons.Rounded.NotificationsActive, contentDescription = null, modifier = Modifier.size(40.dp))
                    Text(
                        copy.onboardingPushTitle,
                        style = MaterialTheme.typography.titleLarge,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.semantics { heading() }
                    )
                    Text(copy.onboardingPushText, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = onContinue,
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(vertical = 16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = Color(0xFF5A2400))
            ) {
                Text(copy.continueButton, style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}

@HitzeVPreviews
@Composable
private fun OnboardingScreenPreview() {
    PreviewSurface(german = true) {
        OnboardingScreen(showWelcome = true, onContinue = {})
    }
}
