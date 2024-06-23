package state.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import data.YabaDatasource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import org.koin.core.component.KoinComponent

class DatasourceCUDManager(
    private val datasource: YabaDatasource,
) : ViewModel(), KoinComponent {

    fun onEvent(event: DatasourceCUDEvent) {
        when (event) {
            is DatasourceCUDEvent.CreateFolderCUDEvent -> {
                this.onCreateFolder(
                    name = event.name,
                    icon = event.icon,
                    firstColor = event.firstColor,
                    secondColor = event.secondColor,
                )
            }
            is DatasourceCUDEvent.DeleteFolderCUDEvent -> {
                this.onDeleteFolder(id = event.id)
            }
            is DatasourceCUDEvent.CreateTagCUDEvent -> {
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
            this@DatasourceCUDManager.datasource.createFolder(
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }

    private fun onDeleteFolder(id: Long) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCUDManager.datasource.deleteFolder(id = id)
        }
    }

    private fun onCreateTag(
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@DatasourceCUDManager.datasource.createTag(
                name = name,
                iconName = icon,
                firstColor = firstColor,
                secondColor = secondColor,
            )
        }
    }
}