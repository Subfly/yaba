package core.components.layout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Error
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider

@Composable
fun YabaErrorContent(
    message: String,
    modifier: Modifier = Modifier,
) {
    val themeState = ThemeStateProvider.current
    val localizationState = LocalizationStateProvider.current

    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(
            modifier = Modifier.size(16.dp),
            imageVector = Icons.TwoTone.Error,
            contentDescription = localizationState.accessibility.ERROR_ICON_DESCRIPTION,
            tint = themeState.colors.error,
        )
        Text(
            text = message,
            color = themeState.colors.error,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}
