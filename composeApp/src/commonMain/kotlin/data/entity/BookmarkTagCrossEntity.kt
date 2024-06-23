package data.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index

@Entity(
    tableName = "bookmarks_tags_table",
    primaryKeys = ["bookmark_cross_id", "tag_cross_id"],
    indices = [
        Index(value = ["bookmark_cross_id"]),
        Index(value = ["tag_cross_id"])
    ],
    foreignKeys = [
        ForeignKey(
            entity = BookmarkEntity::class,
            parentColumns = ["bookmark_id"],
            childColumns = ["bookmark_cross_id"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = TagEntity::class,
            parentColumns = ["tag_id"],
            childColumns = ["tag_cross_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
)
data class BookmarkTagCrossEntity(
    @ColumnInfo(name = "bookmark_cross_id")
    var bookmarkId: Long = 0,
    @ColumnInfo(name = "tag_cross_id")
    var tagId: Long = 0,
)
