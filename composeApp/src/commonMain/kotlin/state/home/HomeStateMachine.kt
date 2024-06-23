package state.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.util.mappers.toFolderModel
import core.util.mappers.toTagModel
import data.YabaDatabase
import data.createYabaDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class HomeStateMachine : ViewModel(), KoinComponent {
    private val database = createYabaDatabase(
        builder =
    )
    private val folderRepository = this.database.folderRepository()
    private val tagRepository = this.database.tagRepository()

    private val _state: MutableStateFlow<HomeState> = MutableStateFlow(HomeState())
    val state: StateFlow<HomeState> = _state.asStateFlow()

    init {
        this.viewModelScope.launch(Dispatchers.IO) {
            combine(
                this@HomeStateMachine.folderRepository.getAllFolders(),
                this@HomeStateMachine.tagRepository.getAllTags(),
            ) { folders, tags ->
                withContext(Dispatchers.Main) {
                    _state.update { old ->
                        old.copy(
                            loading = false,
                            folders = folders.map { entity -> entity.toFolderModel() },
                            tags = tags.map { entity -> entity.toTagModel() },
                        )
                    }
                }
            }.launchIn(this)
        }
    }
}