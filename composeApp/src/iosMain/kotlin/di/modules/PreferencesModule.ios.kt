package di.modules

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import core.preferences.createDataStore
import org.koin.core.module.Module
import org.koin.dsl.module

actual val datastorePreferencesModule: Module = module {
    single<DataStore<Preferences>> { createDataStore() }
}