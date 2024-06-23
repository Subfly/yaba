package core.settings.theme

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import core.util.selections.ThemeSelection
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.koin.core.component.KoinComponent

class YabaThemeController(
    private val dataStore: DataStore<Preferences>,
) : KoinComponent {
    private val selectedThemeKey = stringPreferencesKey("selected_theme")

    val selectedThemePreferences: Flow<ThemeSelection> = dataStore.data.map { preferences ->
        val selectedPreference = preferences[selectedThemeKey]
        when (selectedPreference) {
            ThemeSelection.SYSTEM.key -> ThemeSelection.SYSTEM
            ThemeSelection.DARK.key -> ThemeSelection.DARK
            ThemeSelection.LIGHT.key -> ThemeSelection.LIGHT
            else -> DEFAULT_THEME_SELECTION
        }
    }

    suspend fun onNewThemeSelected(newThemeSelection: ThemeSelection) {
        dataStore.edit { preferences ->
            preferences[selectedThemeKey] = newThemeSelection.key
        }
    }

    companion object {
        val DEFAULT_THEME_SELECTION = ThemeSelection.SYSTEM
    }
}