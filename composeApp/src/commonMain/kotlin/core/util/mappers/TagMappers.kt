package core.util.mappers

import core.model.TagModel
import core.util.selections.ColorSelection
import data.entity.TagEntity
import data.util.TagWithBookmarks

fun TagEntity.toTagModel(): TagModel {
    return TagModel(
        id = this.id,
        name = this.name,
        iconName = this.iconName,
        firstColor = this.firstColor?.let { ColorSelection.valueOf(it) },
        secondColor = this.secondColor?.let { ColorSelection.valueOf(it) },
    )
}


fun TagWithBookmarks.toTagModel(): TagModel {
    return TagModel(
        id = this.tag?.id ?: -1,
        name = this.tag?.name ?: "",
        iconName = this.tag?.iconName,
        firstColor = this.tag?.firstColor?.let { ColorSelection.valueOf(it) },
        secondColor = this.tag?.secondColor?.let { ColorSelection.valueOf(it) },
    )
}

fun TagModel.toTagEntity(): TagEntity {
    return TagEntity(
        id = this.id,
        name = this.name,
        iconName = iconName,
        firstColor = this.firstColor?.name,
        secondColor = this.secondColor?.name,
    )
}
