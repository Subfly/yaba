package data

import androidx.room.Room
import androidx.room.RoomDatabase
import java.io.File

fun getDatabaseBuilder(): RoomDatabase.Builder<YabaDatabase> {
    // TODO: CHANGE FILE LOCATION TO UNACCESSIBLE PLACE
    val dbFile = File(System.getProperty("java.io.tmpdir"), "yaba.db")
    return Room.databaseBuilder<YabaDatabase>(
        name = dbFile.absolutePath,
    )
}
