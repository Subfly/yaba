package data.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import core.constants.DatastoreConstants
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant

@Entity(
    tableName = "bookmarks_table",
    foreignKeys = [
        ForeignKey(
            entity = FolderEntity::class,
            parentColumns = ["folder_id"],
            childColumns = ["folder_id"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [
        Index(value = ["folder_id"]),
        Index(value = ["bookmark_id"]),
    ]
)
data class BookmarkEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "bookmark_id")
    val id: Long = 0,
    @ColumnInfo(name = "folder_id")
    /* @ForeignKey */
    val folderId: Long = DatastoreConstants.NON_EXISTANT_FOLDER_ID.toLong(),
    var url: String = "",
    var title: String = "",
    var dateAdded: Instant = Clock.System.now(),
    var isPrivate: Boolean = false,
    var description: String? = null,
    var unfurlData: String? = null,
)
