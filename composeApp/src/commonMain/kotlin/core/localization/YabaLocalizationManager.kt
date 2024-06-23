package core.localization

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import core.localization.assets.YabaLocalizationState
import core.localization.assets.accessibility.EnglishAccessibility
import core.localization.assets.accessibility.TurkishAccessibility
import core.localization.assets.localization.EnglishLocalization
import core.localization.assets.localization.TurkishLocalization
import core.util.selections.LanguageSelection
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent

class YabaLocalizationManager(
    private val controller: YabaLocalizationController,
) : ViewModel(), KoinComponent {
    private val _state: MutableStateFlow<YabaLocalizationState> =
        MutableStateFlow(YabaLocalizationState())
    val state: StateFlow<YabaLocalizationState> = _state.asStateFlow()

    init {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@YabaLocalizationManager
                .controller
                .selectedLanguagePreferences
                .collectLatest { selection ->
                    withContext(Dispatchers.Main) {
                        _state.update {
                            when (selection) {
                                LanguageSelection.TR -> {
                                    it.copy(
                                        currentLocal = selection,
                                        localization = TurkishLocalization(),
                                        accessibility = TurkishAccessibility(),
                                    )
                                }
                                LanguageSelection.EN -> {
                                    it.copy(
                                        currentLocal = selection,
                                        localization = EnglishLocalization(),
                                        accessibility = EnglishAccessibility(),
                                    )
                                }
                            }
                        }
                    }
                }
        }
    }

    fun onNewLanguageSelected(newLanguageSelection: LanguageSelection) {
        this.viewModelScope.launch(Dispatchers.IO) {
            this@YabaLocalizationManager.controller.onNewLanguageSelected(
                newLanguageSelection = newLanguageSelection,
            )
        }
    }
}
