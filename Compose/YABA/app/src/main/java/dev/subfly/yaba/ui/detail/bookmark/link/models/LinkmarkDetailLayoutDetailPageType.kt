package dev.subfly.yaba.ui.detail.bookmark.link.models

internal enum class DetailPage(
    val iconName: String,
    val label: String // TODO: LOCALIZATION
) {
    INFO(iconName = "information-circle", label = "Info"),
    CONTENTS(iconName = "align-box-middle-center", label = "Contents"),
}
