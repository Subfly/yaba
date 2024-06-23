package core.util.mappers

import core.model.BookmarkModel
import data.entity.BookmarkEntity
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toInstant
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import unfurl.models.UnfurlModel

fun BookmarkEntity.toBookmarkModel(): BookmarkModel {
    val unfurlData = this.unfurlData?.let {
        Json.decodeFromString<UnfurlModel>(it)
    }

    return BookmarkModel(
        id = this.id,
        folderId = this.folderId,
        url = this.url,
        title = this.title,
        dateAdded = this.dateAdded.toLocalDateTime(
            timeZone = TimeZone.currentSystemDefault(),
        ),
        description = this.description,
        isPrivate = this.isPrivate,
        unfurlData = unfurlData,
    )
}

fun BookmarkModel.toBookmarkEntity(): BookmarkEntity {
    val unfurlData = this.unfurlData?.let {
        Json.encodeToString<UnfurlModel>(it)
    }

    return BookmarkEntity(
        id = this.id,
        folderId = this.folderId,
        url = this.url,
        title = this.title,
        dateAdded = this.dateAdded.toInstant(
            timeZone = TimeZone.UTC,
        ),
        description = this.description,
        isPrivate = this.isPrivate,
        unfurlData = unfurlData,
    )
}
