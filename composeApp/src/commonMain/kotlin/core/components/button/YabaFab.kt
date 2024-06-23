package core.components.button

import Platform
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.SmallFloatingActionButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import core.settings.theme.ThemeStateProvider
import currentPlatform

@Composable
fun YabaFab(
    onClick: () -> Unit,
    isMini: Boolean = false,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val themeState = ThemeStateProvider.current

    if (currentPlatform == Platform.DESKTOP) {
        ExtendedFloatingActionButton(
            modifier = modifier,
            onClick = onClick,
            containerColor = themeState.colors.secondary,
            contentColor = themeState.colors.onSecondary,
        ) {
            content()
        }
    } else {
        if (isMini) {
            SmallFloatingActionButton(
                modifier = modifier,
                onClick = onClick,
                content = content,
                containerColor = themeState.colors.secondary,
                contentColor = themeState.colors.onSecondary,
            )
        } else {
            FloatingActionButton(
                modifier = modifier,
                onClick = onClick,
                content = content,
                containerColor = themeState.colors.secondary,
                contentColor = themeState.colors.onSecondary,
            )
        }
    }
}
