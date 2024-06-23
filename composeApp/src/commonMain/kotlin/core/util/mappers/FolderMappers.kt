package core.util.mappers

import core.model.FolderModel
import core.util.icon.YabaIcons
import core.util.selections.ColorSelection
import dev.subfly.FolderEntity

fun FolderEntity.toFolderModel(): FolderModel {
    val icon = YabaIcons.entries.firstOrNull { it.key == this.icon_name }

    return FolderModel(
        id = this.folder_id,
        name = this.name,
        icon = icon,
        firstColor = this.first_color?.let { ColorSelection.valueOf(it) },
        secondColor = this.second_color?.let { ColorSelection.valueOf(it) },
    )
}
