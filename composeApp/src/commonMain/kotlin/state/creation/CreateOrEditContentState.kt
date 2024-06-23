package state.creation

data class CreateOrEditContentState(
    val shouldShowCreateBookmarkSheet: Boolean = false,
    val shouldShowCreateFolderSheet: Boolean = false,
    val shouldShowCreateTagSheet: Boolean = false,
)
