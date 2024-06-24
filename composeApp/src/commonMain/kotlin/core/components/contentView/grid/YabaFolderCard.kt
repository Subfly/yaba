package core.components.contentView.grid

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Delete
import androidx.compose.material.icons.twotone.Edit
import androidx.compose.material.icons.twotone.MoreVert
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.layout.YabaCard
import core.components.layout.YabaMenu
import core.components.layout.YabaMenuItem
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.icon.YabaIcons
import core.util.selections.ColorSelection
import state.creation.CreateOrEditContentStateMachineProvider
import state.manager.DatasourceCRUDEvent
import state.manager.DatasourceCRUDManagerProvider

@Composable
fun YabaFolderGridItem(
    modifier: Modifier = Modifier,
    folderId: Long,
    folderName: String,
    bookmarkCount: Long,
    icon: ImageVector?,
    iconDescription: String?,
    firstColor: Color?,
    secondColor: Color?,
    isInCreateOrEditMode: Boolean = false,
    onClickFolder: () -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    val crudManager = DatasourceCRUDManagerProvider.current
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current

    var isMenuExpanded by remember { mutableStateOf(false) }

    val bookmarkCountText = buildAnnotatedString {
        if (bookmarkCount == 0L) {
            append(localizationProvider.localization.NO_BOOKMARKS_CARD_MESSAGE)
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

    YabaCard(
        modifier = modifier.fillMaxWidth(),
        requireBorder = true,
        customBorderBrushColors = listOf(
            firstColor ?: ColorSelection.PRIMARY.color,
            secondColor ?: ColorSelection.SECONDARY.color,
        ),
        onClick = onClickFolder,
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
        ) {
            Column(
                modifier = Modifier.align(Alignment.TopStart),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Box(
                    modifier = Modifier
                        .padding(
                            start = 12.dp,
                            top = 12.dp,
                        )
                        .size(64.dp)
                        .background(
                            brush = Brush.linearGradient(
                                colors = listOf(
                                    firstColor ?: ColorSelection.PRIMARY.color,
                                    secondColor ?: ColorSelection.SECONDARY.color,
                                )
                            ),
                            shape = RoundedCornerShape(8.dp),
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = icon ?: YabaIcons.FOLDER.icon,
                        contentDescription = iconDescription,
                        modifier = Modifier.size(36.dp),
                        tint = themeState.colors.creamyWhite,
                    )
                }
                Column(
                    modifier = Modifier.padding(
                        start = 12.dp,
                        bottom = 12.dp,
                    ),
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
            Box(
                modifier = Modifier
                    .padding(
                        end = 12.dp,
                        top = 12.dp,
                    )
                    .align(Alignment.TopEnd),
            ) {
                Icon(
                    modifier = Modifier
                        .clickable {
                            if (isInCreateOrEditMode.not()) {
                                isMenuExpanded = true
                            }
                        },
                    imageVector = Icons.TwoTone.MoreVert,
                    contentDescription = localizationProvider.accessibility.SHOW_MORE_ICON_DESCRIPTION,
                    tint = themeState.colors.onBackground,
                )
                OptionsMenu(
                    isExpanded = isMenuExpanded,
                    onDismissRequest = {
                        isMenuExpanded = false
                    },
                    onClickDelete = {
                        isMenuExpanded = false
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.DeleteFolderCRUDEvent(
                                id = folderId,
                            )
                        )
                    },
                    onClickEdit = {
                        isMenuExpanded = false
                        createOrEditContentStateMachine?.onShowFolderContent(
                            folderId = folderId,
                        )
                    }
                )
            }
        }
    }
}

@Composable
private fun OptionsMenu(
    isExpanded: Boolean,
    modifier: Modifier = Modifier,
    onDismissRequest: () -> Unit,
    onClickEdit: () -> Unit,
    onClickDelete: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    YabaMenu(
        modifier = modifier,
        expanded = isExpanded,
        onDismissRequest = onDismissRequest,
    ) {
        YabaMenuItem(
            text = {
                Text(localizationProvider.localization.EDIT_TITLE)
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.TwoTone.Edit,
                    contentDescription = localizationProvider.accessibility.EDIT_ICON_DESCRIPTION,
                )
            },
            onClick = onClickEdit,
        )
        YabaMenuItem(
            text = {
                Text(localizationProvider.localization.DELETE_TITLE)
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.TwoTone.Delete,
                    contentDescription = localizationProvider.accessibility.DELETE_ICON_DESCRIPTION,
                )
            },
            onClick = onClickDelete,
        )
    }
}
