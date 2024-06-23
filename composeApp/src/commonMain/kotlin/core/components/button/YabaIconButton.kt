package core.components.button

import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import core.theme.ThemeStateProvider

@Composable
fun YabaIconButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    content: @Composable () -> Unit
) {
    val themeState = ThemeStateProvider.current

    IconButton(
        modifier = modifier,
        onClick = onClick,
        content = content,
        enabled = enabled,
        colors = IconButtonDefaults.iconButtonColors().copy(
            containerColor = Color.Transparent,
            contentColor = themeState.colors.onBackground,
        ),
    )
}
