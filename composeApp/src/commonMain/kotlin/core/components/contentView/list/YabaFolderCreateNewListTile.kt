package core.components.contentView.list

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.ChevronRight
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
fun YabaFolderCreateNewListTile(
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
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .border(
                            width = 2.dp,
                            brush = Brush.linearGradient(
                                colors = listOf(
                                    ColorSelection.PRIMARY.color,
                                    ColorSelection.SECONDARY.color,
                                )
                            ),
                            shape = CircleShape,
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = Icons.TwoTone.CreateNewFolder,
                        contentDescription = localizationProvider.accessibility.CREATE_FOLDER_ICON_DESCRIPTION,
                        modifier = Modifier.size(28.dp),
                        tint = themeState.colors.creamyWhite,
                    )
                }
                Text(
                    text = localizationProvider.localization.CREATE_FOLDER,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            Icon(
                modifier = Modifier.clickable(onClick = onClick),
                imageVector = Icons.TwoTone.ChevronRight,
                contentDescription = localizationProvider.accessibility.OPEN_CONTENT_DESCRIPTION,
                tint = themeState.colors.onBackground,
            )
        }
    }
}
