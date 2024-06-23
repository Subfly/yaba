package core.components.button

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.dp
import core.theme.ThemeStateProvider

@Composable
fun YabaOutlineButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    shape: Shape = RoundedCornerShape(8.dp),
    content: @Composable RowScope.() -> Unit
) {
    val themeState = ThemeStateProvider.current

    OutlinedButton(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        shape = shape,
        content = content,
        border = BorderStroke(
            width = 2.dp,
            color = themeState.colors.primary,
        ),
        colors = ButtonDefaults.outlinedButtonColors().copy(
            containerColor = Color.Transparent,
            contentColor = themeState.colors.onBackground,
        )
    )
}
