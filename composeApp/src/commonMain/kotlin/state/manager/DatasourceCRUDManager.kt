package state.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.model.FolderModel
import core.util.mappers.toFolderModel
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

    fun onEvent(event: DatasourceCRUDEvent) {
        when (event) {
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
            is DatasourceCRUDEvent.CreateTagCRUDEvent -> {
                this.onCreateTag(
                    name = event.name,
                    icon = event.icon,
                    firstColor = event.firstColor,
                    secondColor = event.secondColor,
                )
            }
        }
    }

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
}