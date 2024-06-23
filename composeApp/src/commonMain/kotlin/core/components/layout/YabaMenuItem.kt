package core.components.layout

import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MenuDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import core.settings.theme.ThemeStateProvider

@Composable
fun YabaMenuItem(
    text: @Composable () -> Unit,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
) {
    val themeState = ThemeStateProvider.current

    DropdownMenuItem(
        text = text,
        onClick = onClick,
        modifier = modifier,
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        colors = MenuDefaults.itemColors().copy(
            textColor = themeState.colors.onSurface,
            leadingIconColor = themeState.colors.onSurface,
            trailingIconColor = themeState.colors.onSurface,
        )
    )
}
