package state.detail.tag

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.util.mappers.toBookmarkModel
import data.YabaDatasource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class TagDetailStateMachine : ViewModel(), KoinComponent {
    private val datasource by inject<YabaDatasource>()

    private var fetchBookmarksJob: Job? = null
    private val _state = MutableStateFlow(TagDetailState())
    val state: StateFlow<TagDetailState> = _state.asStateFlow()

    fun fetchBookmarks(tagId: Long) {
        this.fetchBookmarksJob?.cancel()
        this.fetchBookmarksJob = this.viewModelScope.launch(Dispatchers.IO) {
            this@TagDetailStateMachine
                .datasource
                .getBookmarksOfTag(
                    tagId = tagId
                ).collectLatest { bookmarks ->
                    val mapped = bookmarks.map { it.toBookmarkModel() }
                    withContext(Dispatchers.Main) {
                        this@TagDetailStateMachine._state.update {
                            it.copy(
                                isLoading = false,
                                bookmarks = mapped
                            )
                        }
                    }
                }
        }
    }

    fun dispose() {
        this.fetchBookmarksJob?.cancel()
    }
}
