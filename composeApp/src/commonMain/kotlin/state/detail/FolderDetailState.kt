package state.detail

import core.model.BookmarkModel

data class FolderDetailState(
    val isLoading: Boolean = true,
    val bookmarks: List<BookmarkModel> = emptyList()
)
