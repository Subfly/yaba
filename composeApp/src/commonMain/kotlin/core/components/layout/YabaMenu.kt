package core.components.layout

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.material3.DropdownMenu
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.PopupProperties
import core.theme.ThemeStateProvider

@Composable
fun YabaMenu(
    expanded: Boolean,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    val themeState = ThemeStateProvider.current

    DropdownMenu(
        offset = DpOffset(x = (-24).dp, y = 0.dp),
        expanded = expanded,
        onDismissRequest = onDismissRequest,
        modifier = modifier
            .background(color = themeState.colors.surface),
        content = content,
        properties = PopupProperties(focusable = true),
    )
}
