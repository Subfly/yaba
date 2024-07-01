package core.util.mappers

import core.model.BookmarkModel
import dev.subfly.BookmarkEntity
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.format.DateTimeComponents
import kotlinx.datetime.toLocalDateTime

fun BookmarkEntity.toBookmarkModel(): BookmarkModel {
    return BookmarkModel(
        id = this.bookmark_id,
        folderId = this.folder_id,
        url = this.url,
        title = this.title,
        dateAdded = Instant.parse(
            input = this.date_added,
            format = DateTimeComponents.Formats.ISO_DATE_TIME_OFFSET,
        ).toLocalDateTime(
            timeZone = TimeZone.currentSystemDefault()
        )
    )
}