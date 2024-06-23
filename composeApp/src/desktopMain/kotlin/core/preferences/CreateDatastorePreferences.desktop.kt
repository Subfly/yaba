package core.preferences

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import java.io.File

fun createDataStore(): DataStore<Preferences> = createDataStore {
    // TODO: CHANGE FILE LOCATION TO UNACCESSIBLE PLACE
    val dbFile = File(System.getProperty("java.io.tmpdir"), dataStoreFileName)
    dbFile.absolutePath
}