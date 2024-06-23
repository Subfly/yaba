package core.settings.theme.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import core.settings.theme.assets.YabaTypography

@Composable
fun YabaTheme(
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        typography = YabaTypography.getTypography(),
    ) {
        content()
    }
}
