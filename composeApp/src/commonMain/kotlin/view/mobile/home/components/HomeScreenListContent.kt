package view.mobile.home.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.CreateNewFolder
import androidx.compose.material.icons.twotone.NewLabel
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import core.components.contentView.YabaTag
import core.components.contentView.list.YabaFolderListTile
import core.components.layout.YabaNoContentLayout
import core.settings.localization.LocalizationStateProvider
import state.content.ContentState
import state.creation.CreateOrEditContentStateMachineProvider
import state.manager.DatasourceCRUDEvent
import state.manager.DatasourceCRUDManagerProvider

@OptIn(ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
fun HomeScreenListContent(
    state: ContentState,
    modifier: Modifier = Modifier,
    onClickFolder: (Long, String) -> Unit,
    onClickTag: (Long, String) -> Unit,
) {
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current
    val localizationProvider = LocalizationStateProvider.current
    val crudManager = DatasourceCRUDManagerProvider.current

    var shouldExtendFolders by remember { mutableStateOf(true) }
    var shouldExtendTags by remember { mutableStateOf(true) }

    LazyColumn(
        modifier = modifier,
    ) {
        item {
            HomeTitle(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                title = localizationProvider.localization.TAGS_TITLE,
                expanded = shouldExtendTags,
                onClick = { shouldExtendTags = it }
            )
        }
        if (shouldExtendTags) {
            if (state.tags.isEmpty()) {
                item {
                    YabaNoContentLayout(
                        label = localizationProvider.localization.NO_TAGS_HOME_LABEL,
                        message = localizationProvider.localization.NO_TAGS_HOME_MESSAGE,
                        icon = Icons.TwoTone.NewLabel,
                        iconDescription = localizationProvider.accessibility.NO_TAG_ICON_DESCRIPTION,
                        isFullscreen = false,
                    )
                }
            } else {
                item {
                    FlowRow(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        state.tags.forEach { tag ->
                            YabaTag(
                                modifier = Modifier.animateItemPlacement(),
                                selected = true,
                                name = tag.name,
                                firstColor = tag.firstColor?.color,
                                secondColor = tag.secondColor?.color,
                                icon = tag.icon?.icon,
                                iconDescription = tag.icon?.key,
                                onClick = {
                                    onClickTag.invoke(tag.id, tag.name)
                                },
                                onLongClick = {
                                    createOrEditContentStateMachine?.onShowTagContent(
                                        tagId = tag.id,
                                    )
                                },
                            )
                        }
                    }
                }
            }
        }
        item {
            HomeTitle(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp)
                    .padding(top = if (shouldExtendTags) 16.dp else 0.dp),
                title = localizationProvider.localization.FOLDERS_TITLE,
                expanded = shouldExtendFolders,
                onClick = { shouldExtendFolders = it }
            )
        }
        if (shouldExtendFolders) {
            if (state.folders.isEmpty()) {
                item {
                    YabaNoContentLayout(
                        label = localizationProvider.localization.NO_FOLDERS_HOME_LABEL,
                        message = localizationProvider.localization.NO_FOLDERS_HOME_MESSAGE,
                        icon = Icons.TwoTone.CreateNewFolder,
                        iconDescription = localizationProvider.accessibility.NO_FOLDER_ICON_DESCRIPTION,
                        isFullscreen = false,
                    )
                }
            } else {
                items(
                    state.folders,
                    key = { it.id }
                ) { folder ->
                    YabaFolderListTile(
                        modifier = Modifier
                            .animateItemPlacement()
                            .padding(bottom = 12.dp),
                        folderName = folder.name,
                        bookmarkCount = folder.bookmarkCount ?: 0L,
                        icon = folder.icon?.icon,
                        iconDescription = folder.icon?.key,
                        firstColor = folder.firstColor?.color,
                        secondColor = folder.secondColor?.color,
                        onDeleteSwipe = {
                            crudManager?.onEvent(
                                event = DatasourceCRUDEvent.DeleteFolderCRUDEvent(
                                    id = folder.id,
                                )
                            )
                        },
                        onEditSwipe = {
                            // TODO: ADD EDIT FOLDER FUNCTIONALITY
                        },
                        onClickFolder = {
                            onClickFolder.invoke(folder.id, folder.name)
                        },
                    )
                }
            }
        }
    }
}
