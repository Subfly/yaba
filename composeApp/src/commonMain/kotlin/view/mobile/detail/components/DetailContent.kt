package view.mobile.detail.components

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
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import core.components.button.YabaFab
import core.components.contentView.grid.YabaBookmarkCard
import core.components.contentView.list.YabaBookmarkListTile
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.model.BookmarkModel
import core.settings.contentview.ContentViewStyleStateProvider
import core.settings.localization.LocalizationStateProvider
import core.util.selections.ContentViewSelection
import state.creation.CreateOrEditContentStateMachineProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailContent(
    title: String,
    isLoading: Boolean,
    bookmarks: List<BookmarkModel>,
    appBarFirstColor: Color,
    appBarSecondColor: Color,
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
    onClickEditOption: () -> Unit,
    onClickDeleteOption: () -> Unit,
) {
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current
    val viewSelectionState = ContentViewStyleStateProvider.current
    val localizationState = LocalizationStateProvider.current

    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    YabaScaffold (
        modifier = modifier
            .fillMaxSize()
            .nestedScroll(connection = scrollBehavior.nestedScrollConnection),
        topBar = {
            DetailAppBar(
                title = title,
                scrollBehavior = scrollBehavior,
                isLoading = isLoading,
                firstColor = appBarFirstColor,
                secondColor = appBarSecondColor,
                onClickBack = onClickBack,
                onClickEdit = onClickEditOption,
                onClickDelete = onClickDeleteOption,
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
        if (isLoading.not()) {
            if (bookmarks.isEmpty()) {
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
                            items(bookmarks) { bookmark ->
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
                            items(bookmarks) { bookmark ->
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