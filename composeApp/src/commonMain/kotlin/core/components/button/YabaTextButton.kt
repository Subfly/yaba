package core.components.button

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.RowScope
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import core.theme.ThemeStateProvider
import core.theme.assets.YabaColors

@Composable
fun YabaTextButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    content: @Composable RowScope.() -> Unit
) {
    val themeState = ThemeStateProvider.current

    TextButton(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        content = content,
        colors = ButtonDefaults.textButtonColors().copy(
            containerColor = Color.Transparent,
            contentColor = themeState.colors.primary,
        )
    )
}
