package core.components.contentView.grid

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.CreateNewFolder
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.layout.YabaCard
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.selections.ColorSelection

@Composable
fun YabaFolderCreateNewGridCard(
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    YabaCard(
        modifier = modifier.fillMaxWidth(),
        requireBorder = true,
        customBorderBrushColors = listOf(
            ColorSelection.PRIMARY.color,
            ColorSelection.SECONDARY.color,
        ),
        onClick = onClick,
    ) {
        Row (
            modifier = Modifier.padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .border(
                        width = 2.dp,
                        brush = Brush.linearGradient(
                            colors = listOf(
                                ColorSelection.PRIMARY.color,
                                ColorSelection.SECONDARY.color,
                            )
                        ),
                        shape = RoundedCornerShape(8.dp),
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.TwoTone.CreateNewFolder,
                    contentDescription = localizationProvider.accessibility.CREATE_FOLDER_ICON_DESCRIPTION,
                    modifier = Modifier.size(36.dp),
                    tint = themeState.colors.creamyWhite,
                )
            }
            Text(
                text = localizationProvider.localization.CREATE_FOLDER,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}
