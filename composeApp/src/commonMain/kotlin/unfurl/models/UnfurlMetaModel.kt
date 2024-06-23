package unfurl.models

import kotlinx.datetime.LocalDateTime
import kotlinx.serialization.Serializable

@Serializable
data class UnfurlMetaModel(
    val publisher: String? = null,
    val author: String? = null,
    val publishedTime: LocalDateTime? = null,
)
