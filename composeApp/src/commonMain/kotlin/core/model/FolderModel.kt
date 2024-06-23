package core.model

import core.util.selections.ColorSelection

data class FolderModel(
    val id: Long,
    val name: String,
    val iconName: String? = null,
    val firstColor: ColorSelection? = null,
    val secondColor: ColorSelection? = null,
    val bookmarkCount: Int? = null,
)
