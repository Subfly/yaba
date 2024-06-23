package core.util.mappers

import core.model.TagModel
import core.util.icon.YabaIcons
import core.util.selections.ColorSelection
import dev.subfly.TagEntity

fun TagEntity.toTagModel(): TagModel {
    val icon = YabaIcons.entries.firstOrNull { it.key == this.icon_name }

    return TagModel(
        id = this.tag_id,
        name = this.name,
        icon = icon,
        firstColor = this.first_color?.let { ColorSelection.valueOf(it) },
        secondColor = this.second_color?.let { ColorSelection.valueOf(it) },
    )
}
