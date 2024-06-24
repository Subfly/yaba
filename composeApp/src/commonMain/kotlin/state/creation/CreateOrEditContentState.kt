package state.creation

data class CreateOrEditContentState(
    val shouldShowCreateBookmarkSheet: Boolean = false,
    val shouldShowCreateFolderSheet: Boolean = false,
    val shouldShowCreateTagSheet: Boolean = false,
    val editingFolderId: Long? = null,
    val editingTagId: Long? = null,
    val editingBookmarkId: Long? = null,
)
