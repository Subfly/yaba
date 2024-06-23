package core.model

import kotlinx.datetime.LocalDateTime
import unfurl.models.UnfurlModel

data class BookmarkModel(
    val id: Long,
    val folderId: Long,
    val url: String,
    val title: String,
    val dateAdded: LocalDateTime,
    val description: String? = null,
    val isPrivate: Boolean = false,
    val unfurlData: UnfurlModel? = null,
)
