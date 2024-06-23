package unfurl.models

import kotlinx.serialization.Serializable

@Serializable
sealed class UnfurlModel {
    data class Success(
        val oEmbedModel: UnfurlOEmbedModel? = null,
        val twitterModel: UnfurlTwitterModel? = null,
        val metaModel: UnfurlMetaModel? = null,
        val author: String? = null,
    ) : UnfurlModel() {
        // TODO: Add functions
    }

    object None: UnfurlModel()

    object Error : UnfurlModel()
}
