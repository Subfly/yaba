package core.components.layout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material.Text
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import core.settings.theme.ThemeStateProvider

@Composable
fun YabaNoContentLayout(
    label: String,
    message: String? = null,
    icon: ImageVector? = null,
    iconDescription: String? = null,
    isFullscreen: Boolean = true,
    modifier: Modifier = Modifier,
) {
    val themeState = ThemeStateProvider.current

    Column(
        modifier = modifier.then(
            if (isFullscreen) {
                Modifier.fillMaxSize()
            } else {
                Modifier
            }
        ),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        icon?.let {
            Icon(
                modifier = Modifier.size(
                    if (isFullscreen) 96.dp else 32.dp,
                ),
                imageVector = it,
                contentDescription = iconDescription,
                tint = themeState.colors.onBackground.copy(alpha = 0.8f),
            )
        }

        Spacer(
            modifier = Modifier.size(
                if (isFullscreen) 36.dp else 16.dp,
            )
        )

        Text(
            text = label,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold,
            color = themeState.colors.onBackground.copy(alpha = 0.8f),
        )

        Spacer(
            modifier = Modifier.size(
                if (isFullscreen) 16.dp else 4.dp,
            )
        )

        message?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodyLarge,
                color = themeState.colors.onBackground.copy(alpha = 0.8f),
                textAlign = TextAlign.Center,
            )
        }
    }
}