package view.mobile.creation.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Add
import androidx.compose.material.icons.twotone.Clear
import androidx.compose.material.icons.twotone.CreateNewFolder
import androidx.compose.material.icons.twotone.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastFilter
import core.components.button.YabaTag
import core.components.contentView.grid.YabaFolderCreateNewGridCard
import core.components.contentView.grid.YabaFolderGridItem
import core.components.contentView.list.YabaFolderCreateNewListTile
import core.components.contentView.list.YabaFolderListTile
import core.components.layout.YabaModalSheet
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.components.layout.YabaTextField
import core.model.FolderModel
import core.settings.contentview.ContentViewStyleStateProvider
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.selections.ContentViewSelection
import state.content.ContentStateProvider
import state.creation.CreateOrEditContentStateMachineProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SelectFolderContent(
    sheetState: SheetState,
    modifier: Modifier = Modifier,
    onDismissRequest: () -> Unit,
    onFolderSelected: (Long) -> Unit,
) {
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current
    val contentState = ContentStateProvider.current
    val contentViewStyleState = ContentViewStyleStateProvider.current
    val localizationProvider = LocalizationStateProvider.current
    val themeState = ThemeStateProvider.current

    var query by remember { mutableStateOf("") }
    val folders by remember(query, contentState.folders) {
        derivedStateOf {
            if (query.isEmpty()) {
                contentState.folders
            } else {
                contentState.folders.fastFilter {
                    it.name.lowercase().contains(query.trim().lowercase())
                }
            }
        }
    }

    YabaModalSheet(
        modifier = modifier
            .fillMaxWidth()
            .fillMaxHeight(0.95f),
        sheetState = sheetState,
        onDismissRequest = onDismissRequest,
        content = {
            if (folders.isEmpty()) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    YabaNoContentLayout(
                        modifier = Modifier.padding(bottom = 32.dp),
                        label = localizationProvider.localization.NO_FOLDERS_SELECT_FOLDER_LABEL,
                        message = if (query.isEmpty()) {
                            localizationProvider.localization.NO_FOLDERS_SELECT_FOLDER_MESSAGE
                        } else {
                            localizationProvider.localization.NO_FOLDERS_SELECT_FOLDER_FORMATTABLE_MESSAGE(
                                query = query,
                            )
                        },
                        icon = Icons.TwoTone.CreateNewFolder,
                        iconDescription = localizationProvider.accessibility.NO_FOLDER_ICON_DESCRIPTION,
                        isFullscreen = false,
                    )
                    YabaTag(
                        selected = false,
                        name = localizationProvider.localization.CREATE_FOLDER,
                        firstColor = themeState.colors.primary,
                        secondColor = themeState.colors.secondary,
                        icon = Icons.TwoTone.Add,
                        iconDescription = Icons.TwoTone.Add.name,
                        onClick = {
                            createOrEditContentStateMachine?.onShowFolderContent()
                        },
                    )
                }
            } else {
                when (contentViewStyleState.currentStyle) {
                    ContentViewSelection.GRID -> {
                        GridContent(
                            folders = folders,
                            query = query,
                            onQueryChange = {
                                query = it
                            },
                            onClickFolder = onFolderSelected,
                            onClearPressed = {
                                query = ""
                            }
                        )
                    }

                    ContentViewSelection.LIST -> {
                        ListContent(
                            folders = folders,
                            query = query,
                            onQueryChange = {
                                query = it
                            },
                            onClickFolder = onFolderSelected,
                            onClearPressed = {
                                query = ""
                            }
                        )
                    }
                }
            }
        }
    )
}

@Composable
private fun GridContent(
    folders: List<FolderModel>,
    query: String,
    modifier: Modifier = Modifier,
    onQueryChange: (String) -> Unit,
    onClickFolder: (Long) -> Unit,
    onClearPressed: () -> Unit,
) {
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current
    val themeState = ThemeStateProvider.current

    YabaScaffold(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        containerColor = themeState.colors.surface,
        contentColor = themeState.colors.onSurface,
        topBar = {
            SearchField(
                query = query,
                onQueryChange = onQueryChange,
                onClearPressed = onClearPressed,
            )
        }
    ) { paddings ->
        LazyVerticalStaggeredGrid(
            modifier = Modifier.padding(paddings),
            columns = StaggeredGridCells.Fixed(count = 2),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalItemSpacing = 16.dp,
        ) {
            item {
                YabaFolderCreateNewGridCard(
                    onClick = {
                        createOrEditContentStateMachine?.onShowFolderContent()
                    }
                )
            }
            items(folders) { folder ->
                YabaFolderGridItem(
                    folderId = folder.id,
                    folderName = folder.name,
                    bookmarkCount = folder.bookmarkCount ?: 0,
                    icon = folder.icon?.icon,
                    iconDescription = folder.icon?.name,
                    firstColor = folder.firstColor?.color,
                    secondColor = folder.secondColor?.color,
                    onClickFolder = {
                        onClickFolder(folder.id)
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ListContent(
    folders: List<FolderModel>,
    query: String,
    modifier: Modifier = Modifier,
    onQueryChange: (String) -> Unit,
    onClickFolder: (Long) -> Unit,
    onClearPressed: () -> Unit,
) {
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current

    LazyColumn(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
    ) {
        stickyHeader {
            SearchField(
                query = query,
                onQueryChange = onQueryChange,
                onClearPressed = onClearPressed,
            )
        }
        item {
            YabaFolderCreateNewListTile(
                modifier = Modifier.padding(bottom = 12.dp),
                onClick = {
                    createOrEditContentStateMachine?.onShowFolderContent()
                }
            )
        }
        items(folders) { folder ->
            YabaFolderListTile(
                modifier = Modifier.padding(bottom = 12.dp),
                folderName = folder.name,
                bookmarkCount = folder.bookmarkCount ?: 0,
                icon = folder.icon?.icon,
                iconDescription = folder.icon?.name,
                firstColor = folder.firstColor?.color,
                secondColor = folder.secondColor?.color,
                isInCreateOrEditMode = true,
                onClickFolder = {
                    onClickFolder(folder.id)
                },
                onDeleteSwipe = {},
                onEditSwipe = {}
            )
        }
    }
}

@Composable
private fun SearchField(
    query: String,
    modifier: Modifier = Modifier,
    onQueryChange: (String) -> Unit,
    onClearPressed: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    YabaTextField(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 16.dp),
        value = query,
        onValueChange = onQueryChange,
        singleLine = true,
        placeholder = {
            Text(localizationProvider.localization.SEARCH_FIELD_PLACEHOLDER)
        },
        leadingIcon = {
            Icon(
                imageVector = Icons.TwoTone.Search,
                contentDescription = localizationProvider.accessibility.SEARCH_ICON_DESCIPTION,
            )
        },
        trailingIcon = {
            Icon(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .clickable(onClick = onClearPressed),
                imageVector = Icons.TwoTone.Clear,
                contentDescription = localizationProvider.accessibility.CLEAR_SEARCH_FIELD_ICON_DESCRIPTION,
            )
        }
    )
}