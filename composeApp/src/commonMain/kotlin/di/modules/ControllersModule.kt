package di.modules

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import core.settings.localization.YabaLocalizationController
import core.settings.theme.YabaThemeController
import org.koin.core.module.Module
import org.koin.dsl.module

val controllersModule: Module = module {
    single<YabaThemeController> {
        YabaThemeController(dataStore = get<DataStore<Preferences>>())
    }
    single<YabaLocalizationController> {
        YabaLocalizationController(dataStore = get<DataStore<Preferences>>())
    }
}
