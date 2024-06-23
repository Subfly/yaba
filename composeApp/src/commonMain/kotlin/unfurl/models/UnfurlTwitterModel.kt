package unfurl.models

import kotlinx.serialization.Serializable

@Serializable
data class UnfurlTwitterModel(
    val card: TwitterCardType? = null,
    val site: String? = null,
    val creator: String? = null,
    val title: String? = null,
    val description: String? = null,
    val imageUrl: String? = null,
    val extraDataOne: Pair<String?, String?>? = null,
    val extraDataTwo: Pair<String?, String?>? = null,
)
