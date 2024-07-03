package state.detail.folder

import core.model.BookmarkModel

data class FolderDetailState(
    val isLoading: Boolean = true,
    val bookmarks: List<BookmarkModel> = emptyList()
)
