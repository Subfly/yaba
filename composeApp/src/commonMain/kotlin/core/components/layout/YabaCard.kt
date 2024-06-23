package core.components.layout

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import core.theme.ThemeStateProvider
import org.jetbrains.compose.ui.tooling.preview.Preview

@Preview
@Composable
fun YabaCard(
    modifier: Modifier = Modifier,
    requireBorder: Boolean = true,
    onClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    val themeState = ThemeStateProvider.current

    if (onClick != null) {
        Card(
            modifier = modifier,
            shape = RoundedCornerShape(8.dp),
            onClick = onClick,
            content = content,
            border = if (requireBorder) {
                BorderStroke(
                    width = 2.dp,
                    color = themeState.colors.primary.copy(alpha = 0.8f),
                )
            } else {
                null
            },
            colors = CardDefaults.cardColors().copy(
                containerColor = themeState.colors.surface,
                contentColor = themeState.colors.onSurface,
            )
        )
    } else {
        Card(
            modifier = modifier,
            shape = RoundedCornerShape(8.dp),
            content = content,
            border = if (requireBorder) {
                BorderStroke(
                    width = 2.dp,
                    color = themeState.colors.primary.copy(alpha = 0.8f),
                )
            } else {
                null
            },
            colors = CardDefaults.cardColors().copy(
                containerColor = themeState.colors.surface,
                contentColor = themeState.colors.onSurface,
            )
        )
    }
}
