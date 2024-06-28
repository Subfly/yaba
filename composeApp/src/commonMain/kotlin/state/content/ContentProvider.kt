package state.content

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.util.mappers.toFolderModel
import core.util.mappers.toTagModel
import data.YabaDatasource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class ContentProvider : ViewModel(), KoinComponent {
    private val datasource by inject<YabaDatasource>()

    private val _state = MutableStateFlow(ContentState())
    val state = _state.asStateFlow()

    init {
        this.viewModelScope.launch(Dispatchers.IO) {
            combine(
                this@ContentProvider.datasource.getAllFoldersWithBookmarkCount(),
                this@ContentProvider.datasource.getAllTags(),
            ) { folders, tags ->
                val mappedFolders = folders.map { it.toFolderModel() }
                val mappedTags = tags.map { it.toTagModel() }

                withContext(Dispatchers.Main) {
                    _state.update {
                        it.copy(
                            folders = mappedFolders,
                            tags = mappedTags,
                            loading = false,
                        )
                    }
                }
            }.launchIn(this)
        }
    }
}