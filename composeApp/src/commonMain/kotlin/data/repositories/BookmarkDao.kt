package data.repositories

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Upsert
import data.entity.BookmarkEntity
import data.entity.BookmarkTagCrossEntity
import data.util.BookmarkWithTags
import kotlinx.coroutines.flow.Flow

@Dao
interface BookmarkDao {
    // region CREATE / UPDATE
    @Upsert
    suspend fun upsert(entity: BookmarkEntity)

    @Insert
    suspend fun addTagsToBookmark(entities: List<BookmarkTagCrossEntity>)
    // endregion CREATE / UPDATE

    // region READ
    @Transaction
    @Query("SELECT * FROM bookmarks_table")
    fun getAllBookmarks(): Flow<List<BookmarkWithTags>>

    @Transaction
    @Query("SELECT * FROM bookmarks_table WHERE bookmark_id = (:id)")
    suspend fun getBookmark(id: Int): BookmarkWithTags
    // endregion READ

    // region DELETE
    @Delete
    suspend fun delete(entity: BookmarkEntity)

    @Query("DELETE FROM bookmarks_table WHERE bookmark_id = (:id)")
    suspend fun delete(id: Int)

    @Query("DELETE FROM bookmarks_table WHERE bookmark_id in (:entities)")
    suspend fun deleteBulk(entities: List<Int>)
    // endregion DELETE
}
