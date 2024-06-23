package core.util.mappers

import core.model.FolderModel
import core.util.selections.ColorSelection
import data.entity.FolderEntity
import data.util.FolderWithBookmarks

fun FolderEntity.toFolderModel(): FolderModel {
    return FolderModel(
        id = this.id,
        name = this.name,
        iconName = this.iconName,
        firstColor = this.firstColor?.let { ColorSelection.valueOf(it) },
        secondColor = this.secondColor?.let { ColorSelection.valueOf(it) },
    )
}

fun FolderWithBookmarks.toFolderModel(): FolderModel {
    return FolderModel(
        id = this.folder?.id ?: -1,
        name = this.folder?.name ?: "",
        iconName = this.folder?.iconName,
        firstColor = this.folder?.firstColor?.let { ColorSelection.valueOf(it) },
        secondColor = this.folder?.secondColor?.let { ColorSelection.valueOf(it) },
        bookmarkCount = this.bookmarks.size,
    )
}

fun FolderModel.toFolderEntity(): FolderEntity {
    return FolderEntity(
        id = this.id,
        name = this.name,
        iconName = this.iconName,
        firstColor = this.firstColor?.name,
        secondColor = this.secondColor?.name,
    )
}
