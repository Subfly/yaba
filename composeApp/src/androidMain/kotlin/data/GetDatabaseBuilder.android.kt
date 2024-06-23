package data

import android.content.Context
import androidx.room.Room
import androidx.room.RoomDatabase

fun getDatabaseBuilder(context: Context): RoomDatabase.Builder<YabaDatabase> {
    val appContext = context.applicationContext
    val dbFile = appContext.getDatabasePath("yaba.db")
    return Room.databaseBuilder<YabaDatabase>(
        context = appContext,
        name = dbFile.absolutePath
    )
}
