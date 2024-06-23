package data.repositories

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Upsert
import data.entity.BookmarkTagCrossEntity
import data.entity.TagEntity
import data.util.TagWithBookmarks
import kotlinx.coroutines.flow.Flow

@Dao
interface TagDao {
    // region CREATE / UPDATE
    @Upsert
    suspend fun upsert(entity: TagEntity)

    @Insert
    suspend fun addBookmarksToTag(entities: List<BookmarkTagCrossEntity>)
    // endregion CREATE / UPDATE

    // region READ
    @Transaction
    @Query("SELECT * FROM tags_table")
    fun getAllTags(): Flow<List<TagWithBookmarks>>

    @Transaction
    @Query("SELECT * FROM tags_table WHERE tag_id = (:id)")
    suspend fun getTag(id: Int): TagWithBookmarks
    // endregion READ

    // region DELETE
    @Delete
    suspend fun delete(entity: TagEntity)

    @Query("DELETE FROM tags_table WHERE tag_id = (:id)")
    suspend fun delete(id: Int)

    @Query("DELETE FROM tags_table WHERE tag_id in (:ids)")
    suspend fun deleteBulk(ids: List<Int>)
    // endregion DELETE
}
