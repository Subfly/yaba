package data

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import data.entity.BookmarkEntity
import data.entity.BookmarkTagCrossEntity
import data.entity.FolderEntity
import data.entity.TagEntity
import data.repositories.BookmarkDao
import data.repositories.FolderDao
import data.repositories.TagDao
import data.util.Converters

@Database(
    entities = [
        FolderEntity::class,
        TagEntity::class,
        BookmarkEntity::class,
        BookmarkTagCrossEntity::class,
    ],
    version = 1,
)
@TypeConverters(Converters::class)
abstract class YabaDatabase : RoomDatabase() {
    abstract fun folderRepository(): FolderDao
    abstract fun tagRepository(): TagDao
    abstract fun bookmarkRepository(): BookmarkDao
}
