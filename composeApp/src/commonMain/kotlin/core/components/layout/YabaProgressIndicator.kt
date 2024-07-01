package core.components.layout

import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import core.settings.theme.ThemeStateProvider

@Composable
fun YabaProgressIndicator(
    modifier: Modifier = Modifier
) {
    val themeState = ThemeStateProvider.current

    LinearProgressIndicator(
        modifier = modifier,
        color = themeState.colors.secondary.copy(alpha = 0.5f),
        trackColor = themeState.colors.secondary,
    )
}