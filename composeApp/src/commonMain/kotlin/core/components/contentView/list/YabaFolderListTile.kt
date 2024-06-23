package core.components.contentView.list

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.MoreVert
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.layout.YabaCard
import core.localization.LocalizationStateProvider
import core.theme.ThemeStateProvider
import core.util.icon.YabaIcons
import core.util.selections.ColorSelection

@Composable
fun YabaFolderListTile(
    modifier: Modifier = Modifier,
    folderName: String,
    bookmarkCount: Int,
    icon: ImageVector?,
    iconDescription: String?,
    firstColor: Color?,
    secondColor: Color?,
    onClickFolder: () -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    val bookmarkCountText = buildAnnotatedString {
        val firstText = localizationProvider.localization.BOOKMARK_COUNT_PREFIX_TEXT
        append(firstText)
        addStyle(
            style = MaterialTheme.typography.titleSmall.copy(
                fontWeight = FontWeight.SemiBold
            ).toSpanStyle(),
            start = 0,
            end = firstText.length,
        )
        append(bookmarkCount.toString())
        addStyle(
            style = MaterialTheme.typography.bodyLarge.copy(
                fontWeight = FontWeight.Medium,
            ).toSpanStyle(),
            start = firstText.length,
            end = (firstText + bookmarkCount).length
        )
    }

    YabaCard(
        modifier = modifier.fillMaxWidth(),
        onClick = onClickFolder,
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
                        .background(
                            brush = Brush.linearGradient(
                                colors = listOf(
                                    firstColor ?: ColorSelection.PRIMARY.color,
                                    secondColor ?: ColorSelection.SECONDARY.color,
                                )
                            ),
                            shape = CircleShape,
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = icon ?: YabaIcons.FOLDER.icon,
                        contentDescription = iconDescription,
                        modifier = Modifier.size(28.dp),
                        tint = themeState.colors.creamyWhite,
                    )
                }
                Column(
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    horizontalAlignment = Alignment.Start,
                ) {
                    Text(
                        text = folderName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(text = bookmarkCountText)
                }
            }
            Icon(
                modifier = Modifier
                    .clickable {
                        // TODO: OPEN EDIT/DELETE MENU
                    },
                imageVector = Icons.TwoTone.MoreVert,
                contentDescription = localizationProvider.accessibility.SHOW_MORE_ICON_DESCRIPTION,
                tint = themeState.colors.onBackground,
            )
        }
    }
}
