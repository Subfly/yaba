package data.util

import androidx.room.Embedded
import androidx.room.Junction
import androidx.room.Relation
import data.entity.BookmarkEntity
import data.entity.BookmarkTagCrossEntity
import data.entity.FolderEntity
import data.entity.TagEntity

data class BookmarkWithTags(
    @Embedded
    var bookmark: BookmarkEntity? = null,
    @Relation(
        entity = TagEntity::class,
        parentColumn = "bookmark_id",
        entityColumn = "tag_id",
        associateBy = Junction(
            value = BookmarkTagCrossEntity::class,
            parentColumn = "bookmark_cross_id",
            entityColumn = "tag_cross_id",
        )
    )
    var tags: List<TagEntity> = emptyList(),
)

data class TagWithBookmarks(
    @Embedded
    var tag: TagEntity? = null,
    @Relation(
        entity = BookmarkEntity::class,
        parentColumn = "tag_id",
        entityColumn = "bookmark_id",
        associateBy = Junction(
            value = BookmarkTagCrossEntity::class,
            parentColumn = "tag_cross_id",
            entityColumn = "bookmark_cross_id",
        )
    )
    var bookmarks: List<BookmarkEntity> = emptyList(),
)

data class FolderWithBookmarks(
    @Embedded
    var folder: FolderEntity? = null,
    @Relation(
        entity = BookmarkEntity::class,
        parentColumn = "folder_id",
        entityColumn = "folder_id"
    )
    var bookmarks: List<BookmarkEntity> = emptyList(),
)