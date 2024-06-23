package data

import androidx.room.Room
import androidx.room.RoomDatabase
import platform.Foundation.NSHomeDirectory

fun getDatabaseBuilder(): RoomDatabase.Builder<YabaDatabase> {
    val dbFilePath = NSHomeDirectory() + "/yaba.db"
    return Room.databaseBuilder<YabaDatabase>(
        name = dbFilePath,
        factory =  { YabaDatabase::class.instantiateImpl() }
    )
}
