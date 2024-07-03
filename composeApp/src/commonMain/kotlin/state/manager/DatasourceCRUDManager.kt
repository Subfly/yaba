package state.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.model.FolderModel
import core.model.TagModel
import core.util.mappers.toFolderModel
import core.util.mappers.toTagModel
import data.YabaDatasource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent

class DatasourceCRUDManager(
    private val datasource: YabaDatasource,
) : ViewModel(), KoinComponent {

    private var readFolderJob: Job? = null
    private val _readFolderState = MutableStateFlow<FolderModel?>(null)
    val readFolderState = _readFolderState.asStateFlow()

    private val readTagJob: Job? = null
    private val _readTagState = MutableStateFlow<TagModel?>(null)
    val readTagState = _readTagState.asStateFlow()

    fun onEvent(event: DatasourceCRUDEvent) {
        when (event) {

            // region FOLDER
            is DatasourceCRUDEvent.CreateFolderCRUDEvent -> {
                this.onCreateFolder(
                    name = event.name,
                    icon = event.icon,
                    firstColor = event.firstColor,
                    secondColor = event.secondColor,
                )
            }
            is DatasourceCRUDEvent.EditFolderCRUDEvent -> {
                this.onEditFolder(
                    id = event.folderId,
                    name = event.name,
                    icon = event.icon,
                    firstColor = event.firstColor,
                    secondColor = event.secondColor,
                )
            }
            is DatasourceCRUDEvent.GetFolderCRUDEvent -> {
                this.onReadFolder(id = event.id)
            }
            DatasourceCRUDEvent.OnResetFolderState -> {
                this.readFolderJob?.cancel()
                this._readFolderState.update { null }
            }
            is DatasourceCRUDEvent.DeleteFolderCRUDEvent -> {
                this.onDeleteFolder(id = event.id)
            }
            // endregion FOLDER

            // region TAG
            is DatasourceCRUDEvent.CreateTagCRUDEvent -> {
                this.onCreateTag(
                    name = event.name,
                    icon = event.icon,
                    firstColor = event.firstColor,
                    secondColor = event.secondColor,
                )
            }
            is DatasourceCRUDEvent.EditTagCRUDEvent -> {
                this.onEditTag(
                    id = event.tagId,
                    name = event.name,
                    icon = event.icon,
                    firstColor = event.firstColor,
                    secondColor = event.secondColor,
                )
            }
            is DatasourceCRUDEvent.GetTagCRUDEvent -> {
                this.onReadTag(id = event.id)
            }
            DatasourceCRUDEvent.OnResetTagState -> {
                this.readTagJob?.cancel()
                this._readTagState.update { null }
            }
            is DatasourceCRUDEvent.DeleteTagCRUDEvent -> {
                this.onDeleteTag(id = event.id)
            }
            // endregion TAG
        }
    }

    // region FOLDER
    private fun onCreateFolder(
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager.datasource.createFolder(
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }

    private fun onEditFolder(
        id: Long,
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager.datasource.updateFolder(
                id = id,
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }

    private fun onReadFolder(id: Long) {
        this.readFolderJob = this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager
                .datasource
                .getFolder(id = id)
                .collectLatest { folder ->
                    val mapped = folder.toFolderModel()
                    withContext(Dispatchers.Main) {
                        _readFolderState.update { mapped }
                    }
                }
        }
    }

    private fun onDeleteFolder(id: Long) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager.datasource.deleteFolder(id = id)
        }
    }
    // endregion FOLDER

    // region TAG
    private fun onCreateTag(
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager.datasource.createTag(
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }

    private fun onEditTag(
        id: Long,
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager.datasource.updateTag(
                id = id,
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }

    private fun onReadTag(
        id: Long,
    ) {
        this.readFolderJob = this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager
                .datasource
                .getTag(id = id)
                .collectLatest { tag ->
                    val mapped = tag.toTagModel()
                    withContext(Dispatchers.Main) {
                        _readTagState.update { mapped }
                    }
                }
        }
    }

    private fun onDeleteTag(
        id: Long,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCRUDManager.datasource.deleteTag(id = id)
        }
    }
    // endregion TAG
}