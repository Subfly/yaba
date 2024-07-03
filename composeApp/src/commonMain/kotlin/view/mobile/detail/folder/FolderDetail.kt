package view.mobile.detail.folder

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Bookmark
import androidx.compose.material.icons.twotone.BookmarkAdd
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastFirstOrNull
import core.components.button.YabaFab
import core.components.contentView.grid.YabaBookmarkCard
import core.components.contentView.list.YabaBookmarkListTile
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.settings.contentview.ContentViewStyleStateProvider
import core.settings.localization.LocalizationStateProvider
import core.util.extensions.koinViewModel
import core.util.selections.ContentViewSelection
import state.content.ContentStateProvider
import state.creation.CreateOrEditContentStateMachineProvider
import state.detail.FolderDetailStateMachine
import state.manager.DatasourceCRUDEvent
import state.manager.DatasourceCRUDManagerProvider
import view.mobile.detail.folder.components.FolderDetailAppBar

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FolderDetail(
    folderId: Long,
    folderName: String,
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
) {
    val contentState = ContentStateProvider.current
    val crudManager = DatasourceCRUDManagerProvider.current
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current
    val viewSelectionState = ContentViewStyleStateProvider.current
    val localizationState = LocalizationStateProvider.current

    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    val stateMachine = koinViewModel<FolderDetailStateMachine>()
    val state by stateMachine.state.collectAsState()

    val currentFolder by remember(contentState) {
        derivedStateOf {
            contentState.folders.fastFirstOrNull { it.id == folderId }
        }
    }

    LaunchedEffect(Unit) {
        stateMachine.fetchBookmarks(folderId = folderId)
    }

    YabaScaffold (
        modifier = modifier
            .fillMaxSize()
            .nestedScroll(connection = scrollBehavior.nestedScrollConnection),
        topBar = {
            FolderDetailAppBar(
                title = currentFolder?.name ?: folderName,
                scrollBehavior = scrollBehavior,
                isLoading = state.isLoading,
                firstColor = currentFolder?.firstColor?.color ?: Color.Transparent,
                secondColor = currentFolder?.secondColor?.color ?: Color.Transparent,
                onClickBack = {
                    stateMachine.dispose()
                    onClickBack.invoke()
                },
                onClickEdit = {
                    createOrEditContentStateMachine?.onShowFolderContent(
                        folderId = folderId,
                    )
                },
                onClickDelete = {
                    crudManager?.onEvent(
                        event = DatasourceCRUDEvent.DeleteFolderCRUDEvent(
                            id = folderId,
                        )
                    )
                    onClickBack.invoke()
                },
            )
        },
        floatingActionButton = {
            YabaFab(
                onClick = {
                    createOrEditContentStateMachine?.onShowBookmarkContent()
                }
            ) {
                Icon(
                    imageVector = Icons.TwoTone.BookmarkAdd,
                    contentDescription = localizationState.accessibility.CREATE_BOOKMARK_ICON_DESCRIPTION,
                )
            }
        }
    ) { paddings ->
        if (state.isLoading.not()) {
            if (state.bookmarks.isEmpty()) {
                YabaNoContentLayout(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddings),
                    label = localizationState.localization.NO_BOOKMARKS_LABEL,
                    message = localizationState.localization.NO_BOOKMARKS_MESSAGE,
                    icon = Icons.TwoTone.Bookmark,
                    iconDescription = localizationState.accessibility.NO_BOOKMARKS_ICON_DESCRIPTION
                )
            } else {
                when (viewSelectionState.currentStyle) {
                    // TODO: CHANGE IS PRIVATE
                    ContentViewSelection.GRID -> {
                        LazyVerticalStaggeredGrid(
                            modifier = Modifier.padding(paddings),
                            columns = StaggeredGridCells.Fixed(count = 2),
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            verticalItemSpacing = 16.dp,
                        ) {
                            items(state.bookmarks) { bookmark ->
                                YabaBookmarkCard(
                                    title = bookmark.title,
                                    description = bookmark.description.orEmpty(),
                                    parentFolderId = bookmark.folderId,
                                    dateAdded = bookmark.dateAdded,
                                    imageUrl = "",
                                    isPrivate = false,
                                    tags = emptyList(),
                                    onClickBookmark = {
                                        // TODO: NAVIGATE TO BOOKMARK DETAIL
                                    }
                                )
                            }
                        }
                    }
                    ContentViewSelection.LIST -> {
                        LazyColumn(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(paddings),
                        ) {
                            items(state.bookmarks) { bookmark ->
                                YabaBookmarkListTile(
                                    title = bookmark.title,
                                    description = bookmark.description.orEmpty(),
                                    parentFolderId = bookmark.folderId,
                                    dateAdded = bookmark.dateAdded,
                                    imageUrl = "",
                                    isPrivate = false,
                                    tags = emptyList(),
                                    onClickBookmark = {
                                        // TODO: NAVIGATE TO BOOKMARK DETAIL
                                    },
                                    onDeleteSwipe = {
                                        // TODO: ADD ON DELETE BOOKMARK
                                    },
                                    onEditSwipe = {
                                        createOrEditContentStateMachine?.onShowBookmarkContent(
                                            bookmarkId = bookmark.id,
                                        )
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
