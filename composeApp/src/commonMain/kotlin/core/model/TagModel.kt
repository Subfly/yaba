package core.model

import core.util.icon.YabaIcons
import core.util.selections.ColorSelection

data class TagModel(
    val id: Long,
    val name: String,
    val icon: YabaIcons? = null,
    val firstColor: ColorSelection? = null,
    val secondColor: ColorSelection? = null,
    val bookmarkCount: Int? = null,
)
