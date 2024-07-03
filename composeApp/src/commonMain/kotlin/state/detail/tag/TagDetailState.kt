package state.detail.tag

import core.model.BookmarkModel

data class TagDetailState(
    val isLoading: Boolean = true,
    val bookmarks: List<BookmarkModel> = emptyList(),
)
