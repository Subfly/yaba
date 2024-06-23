package core.settings.theme

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.settings.theme.assets.DarkColors
import core.settings.theme.assets.LightColors
import core.util.selections.ThemeSelection
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

class YabaThemeManager(
    private val controller: YabaThemeController,
) : ViewModel(), KoinComponent {
    private val _state: MutableStateFlow<YabaThemeState> = MutableStateFlow(YabaThemeState())
    val state: StateFlow<YabaThemeState> = _state.asStateFlow()

    private var themeCollectionJob: Job? = null
    private var hasReadAnything: Boolean = false

    fun fetchTheme(isSystemInDark: Boolean) {
        this.themeCollectionJob?.cancel()
        this.themeCollectionJob = this.viewModelScope.launch(Dispatchers.IO) {
            this@YabaThemeManager
                .controller
                .selectedThemePreferences
                .collectLatest { selection ->
                    withContext(Dispatchers.Main) {
                        this@YabaThemeManager._state.update {
                            it.copy(
                                currentSelectedTheme = selection,
                                colors = when (selection) {
                                    ThemeSelection.SYSTEM -> {
                                        if (isSystemInDark) DarkColors() else LightColors()
                                    }

                                    ThemeSelection.DARK -> DarkColors()
                                    ThemeSelection.LIGHT -> LightColors()
                                }
                            )
                        }
                        hasReadAnything = true
                    }
                }
        }
    }

    fun onThemeChanged(
        newThemeSelection: ThemeSelection,
        isSystemInDark: Boolean,
    ) {
        if (hasReadAnything.not()) return

        this.viewModelScope.launch {
            this@YabaThemeManager.controller.onNewThemeSelected(
                newThemeSelection = newThemeSelection,
            )
            withContext(Dispatchers.Main) {
                this@YabaThemeManager.fetchTheme(isSystemInDark = isSystemInDark)
            }
        }
    }
}