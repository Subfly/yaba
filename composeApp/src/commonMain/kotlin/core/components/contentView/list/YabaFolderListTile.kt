package core.components.contentView.list

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.ChevronRight
import androidx.compose.material.icons.twotone.Delete
import androidx.compose.material.icons.twotone.Edit
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.layout.YabaCard
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.settings.theme.assets.YabaColors
import core.util.icon.YabaIcons
import core.util.selections.ColorSelection
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun YabaFolderListTile(
    modifier: Modifier = Modifier,
    folderName: String,
    bookmarkCount: Long,
    icon: ImageVector?,
    iconDescription: String?,
    firstColor: Color?,
    secondColor: Color?,
    isInCreateOrEditMode: Boolean = false,
    onClickFolder: () -> Unit,
    onDeleteSwipe: () -> Unit,
    onEditSwipe: () -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    val scope = rememberCoroutineScope()

    val dismissState = rememberSwipeToDismissBoxState(
        initialValue = SwipeToDismissBoxValue.Settled,
        positionalThreshold = { it * 0.5f },
        confirmValueChange = { state ->
            when (state) {
                SwipeToDismissBoxValue.StartToEnd -> {
                    if (isInCreateOrEditMode.not()) {
                        scope.launch {
                            delay(250)
                            onEditSwipe.invoke()
                        }
                    }
                }

                SwipeToDismissBoxValue.EndToStart -> {
                    if (isInCreateOrEditMode.not()) {
                        scope.launch {
                            delay(250)
                            onDeleteSwipe.invoke()
                        }
                    }
                }

                SwipeToDismissBoxValue.Settled -> return@rememberSwipeToDismissBoxState false
            }
            return@rememberSwipeToDismissBoxState true
        }
    )

    val bookmarkCountText = buildAnnotatedString {
        if (bookmarkCount == 0L) {
            val noContentText = localizationProvider.localization.NO_BOOKMARKS_CARD_MESSAGE
            append(noContentText)
            addStyle(
                style = MaterialTheme.typography.bodyMedium.toSpanStyle(),
                start = 0,
                end = noContentText.length,
            )
        } else {
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
    }

    SwipeToDismissBox(
        modifier = modifier.fillMaxWidth(),
        state = dismissState,
        backgroundContent = { BackgroundContent(dismissState) },
        enableDismissFromEndToStart = isInCreateOrEditMode.not(),
        enableDismissFromStartToEnd = isInCreateOrEditMode.not(),
    ) {
        YabaCard(
            modifier = Modifier.fillMaxWidth(),
            requireBorder = true,
            customBorderBrushColors = listOf(
                firstColor ?: ColorSelection.PRIMARY.color,
                secondColor ?: ColorSelection.SECONDARY.color,
            ),
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
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Text(text = bookmarkCountText)
                    }
                }
                Icon(
                    modifier = Modifier.clickable(onClick = onClickFolder),
                    imageVector = Icons.TwoTone.ChevronRight,
                    contentDescription = localizationProvider.accessibility.OPEN_CONTENT_DESCRIPTION,
                    tint = themeState.colors.onBackground,
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BackgroundContent(dismissBoxState: SwipeToDismissBoxState) {
    val themeState = ThemeStateProvider.current
    val localizationState = LocalizationStateProvider.current

    val color = when (dismissBoxState.dismissDirection) {
        SwipeToDismissBoxValue.StartToEnd -> themeState.colors.primary
        SwipeToDismissBoxValue.EndToStart -> themeState.colors.secondary
        SwipeToDismissBoxValue.Settled -> Color.Transparent
    }

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(
                color = color,
                shape = RoundedCornerShape(8.dp)
            )
            .padding(
                horizontal = 12.dp,
                vertical = 8.dp,
            ),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Icon(
            imageVector = Icons.TwoTone.Edit,
            contentDescription = localizationState.accessibility.DELETE_ICON_DESCRIPTION,
            tint = themeState.colors.onPrimary,
        )
        Icon(
            imageVector = Icons.TwoTone.Delete,
            contentDescription = localizationState.accessibility.EDIT_ICON_DESCRIPTION,
            tint = themeState.colors.onSecondary,
        )
    }
}
