package state.creation

import androidx.lifecycle.ViewModel
import data.YabaDatasource
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class CreateOrEditContentStateMachine : ViewModel(), KoinComponent {
    private val datasource by inject<YabaDatasource>()

    private val _state = MutableStateFlow(CreateOrEditContentState())
    val state = _state.asStateFlow()

    fun onShowBookmarkContent(
        bookmarkId: Long? = null,
    ) {
        _state.update {
            it.copy(
                shouldShowCreateBookmarkSheet = true,
                editingBookmarkId = bookmarkId,
            )
        }
    }

    fun onDismissBookmarkContent() {
        _state.update {
            it.copy(
                shouldShowCreateBookmarkSheet = false,
                editingBookmarkId = null,
            )
        }
    }

    fun onShowFolderContent(
        folderId: Long? = null,
    ) {
        _state.update {
            it.copy(
                shouldShowCreateFolderSheet = true,
                editingFolderId = folderId,
            )
        }
    }

    fun onDismissFolderContent() {
        _state.update {
            it.copy(
                shouldShowCreateFolderSheet = false,
                editingFolderId = null,
            )
        }
    }

    fun onShowTagContent(
        tagId: Long? = null,
    ) {
        _state.update {
            it.copy(
                shouldShowCreateTagSheet = true,
                editingTagId = tagId,
            )
        }
    }

    fun onDismissTagContent() {
        _state.update {
            it.copy(
                shouldShowCreateTagSheet = false,
                editingTagId = null,
            )
        }
    }
}