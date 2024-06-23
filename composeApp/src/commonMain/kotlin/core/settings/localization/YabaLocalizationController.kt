package core.settings.localization

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import core.util.selections.LanguageSelection
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.koin.core.component.KoinComponent

class YabaLocalizationController(
    private val dataStore: DataStore<Preferences>,
): KoinComponent {
    private val selectedLanguageKey = stringPreferencesKey("selected_language")

    val selectedLanguagePreferences: Flow<LanguageSelection> = dataStore.data.map { preferences ->
        val selectedPreference = preferences[selectedLanguageKey]
        when (selectedPreference) {
            LanguageSelection.EN.key -> LanguageSelection.EN
            LanguageSelection.TR.key -> LanguageSelection.TR
            else -> DEFAULT_LANGUAGE_SELECTION
        }
    }

    suspend fun onNewLanguageSelected(newLanguageSelection: LanguageSelection) {
        dataStore.edit { preferences ->
            preferences[selectedLanguageKey] = newLanguageSelection.key
        }
    }

    companion object {
        val DEFAULT_LANGUAGE_SELECTION = LanguageSelection.EN
    }
}
