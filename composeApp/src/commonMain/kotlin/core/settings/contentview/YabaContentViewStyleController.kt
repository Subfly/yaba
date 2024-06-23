package core.settings.contentview

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import core.util.selections.ContentViewSelection
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.koin.core.component.KoinComponent

class YabaContentViewStyleController(
    private val dataStore: DataStore<Preferences>,
) : KoinComponent {
    private val selectedContentViewStyleKey = stringPreferencesKey("selected_content_view_style")

    val selectedContentViewStylePreferences: Flow<ContentViewSelection> = dataStore.data.map { preferences ->
        val selectedPreference = preferences[selectedContentViewStyleKey]
        when (selectedPreference) {
            ContentViewSelection.GRID.key -> ContentViewSelection.GRID
            ContentViewSelection.LIST.key -> ContentViewSelection.LIST
            else -> DEFAULT_CONTENT_VIEW_STYLE_SELECTION
        }
    }

    suspend fun onNewStyleSelected(newContentViewSelection: ContentViewSelection) {
        dataStore.edit { preferences ->
            preferences[selectedContentViewStyleKey] = newContentViewSelection.key
        }
    }

    companion object {
        val DEFAULT_CONTENT_VIEW_STYLE_SELECTION = ContentViewSelection.GRID
    }
}