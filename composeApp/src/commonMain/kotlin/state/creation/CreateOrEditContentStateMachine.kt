package state.creation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import data.YabaDatasource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class CreateOrEditContentStateMachine: ViewModel(), KoinComponent {
    private val datasource by inject<YabaDatasource>()

    private val _state = MutableStateFlow(CreateOrEditContentState())
    val state = _state.asStateFlow()

    fun onCreateFolder(
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@CreateOrEditContentStateMachine.datasource.createFolder(
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }

    fun onCreateTag(
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@CreateOrEditContentStateMachine.datasource.createTag(
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }

    fun onShowBookmarkContent(
        isEditMode: Boolean = false,
    ) {
        _state.update {
            it.copy(shouldShowCreateBookmarkSheet = true)
        }
    }

    fun onDismissBookmarkContent() {
        _state.update {
            it.copy(shouldShowCreateBookmarkSheet = false)
        }
    }

    fun onShowFolderContent(
        isEditMode: Boolean = false,
    ) {
        _state.update {
            it.copy(shouldShowCreateFolderSheet = true)
        }
    }

    fun onDismissFolderContent() {
        _state.update {
            it.copy(shouldShowCreateFolderSheet = false)
        }
    }

    fun onShowTagContent(
        isEditMode: Boolean = false,
    ) {
        _state.update {
            it.copy(shouldShowCreateTagSheet = true)
        }
    }

    fun onDismissTagContent() {
        _state.update {
            it.copy(shouldShowCreateTagSheet = false)
        }
    }
}