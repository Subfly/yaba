package core.settings.contentview

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.util.selections.ContentViewSelection
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent

class YabaContentViewStyleManager(
    private val controller: YabaContentViewStyleController,
) : ViewModel(), KoinComponent {
    private val _state = MutableStateFlow<YabaContentViewStyleState>(YabaContentViewStyleState())
    val state = _state.asStateFlow()

    init {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@YabaContentViewStyleManager
                .controller
                .selectedContentViewStylePreferences
                .collectLatest { selection ->
                    withContext(Dispatchers.Main) {
                        _state.update {
                            it.copy(
                                currentStyle = selection,
                            )
                        }
                    }
                }
        }
    }

    fun onNewStyleSelected(newStyle: ContentViewSelection) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@YabaContentViewStyleManager.controller.onNewStyleSelected(
                newContentViewSelection = newStyle,
            )
        }
    }

}