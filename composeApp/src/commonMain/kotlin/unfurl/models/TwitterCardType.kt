package unfurl.models

import kotlinx.serialization.Serializable

@Serializable
enum class TwitterCardType(val value: String) {
    SUMMARY(value = "summary"),
    SUMMARY_LARGE_IMAGE(value = "summary_large_image"),
    APP(value = "app"),
    PLAYER(value = "player"),
}
