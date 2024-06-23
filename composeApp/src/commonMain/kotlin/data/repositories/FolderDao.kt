package data.repositories

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Upsert
import data.entity.FolderEntity
import data.util.FolderWithBookmarks
import kotlinx.coroutines.flow.Flow

@Dao
interface FolderDao {
    // region CREATE / UPDATE
    @Upsert
    suspend fun upsert(entity: FolderEntity)
    // endregion CREATE / UPDATE

    // region READ
    @Transaction
    @Query("SELECT * FROM folders_table")
    fun getAllFolders(): Flow<List<FolderWithBookmarks>>

    @Transaction
    @Query("SELECT * FROM folders_table WHERE folder_id = (:id)")
    suspend fun getFolder(id: Int): FolderWithBookmarks
    // endregion READ

    // region DELETE
    @Delete
    suspend fun delete(entity: FolderEntity)

    @Query("DELETE FROM folders_table WHERE folder_id = (:id)")
    suspend fun delete(id: Int)

    @Query("DELETE FROM folders_table WHERE folder_id in (:ids)")
    suspend fun deleteBulk(ids: List<Int>)
    // endregion DELETE
} 
