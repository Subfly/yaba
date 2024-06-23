package unfurl.models

import kotlinx.serialization.Serializable

@Serializable
data class UnfurlOEmbedModel(
    val url: String? = null,
    val title: String? = null,
    val description: String? = null,
    val siteName: String? = null,
    val imageUrl: String? = null,
    val imageSecureUrl: String? = null,
    val width: Float? = null,
    val height: Float? = null,
)
