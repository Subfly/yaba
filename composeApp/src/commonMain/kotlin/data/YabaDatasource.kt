package data

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import dev.subfly.YabaDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.flowOn

class YabaDatasource(
    private val database: YabaDatabase,
) {
    // region FOLDER
    private val folderQueries = database.folderEntityQueries

    fun getAllFolders() = folderQueries
        .getAll()
        .asFlow()
        .flowOn(Dispatchers.IO)
        .mapToList(Dispatchers.IO)

    fun createFolder(
        name: String,
        iconName: String? = null,
        firstColor: String? = null,
        secondColor: String? = null,
    ) = folderQueries.create(
        name = name,
        iconName = iconName,
        firstColor = firstColor,
        secondColor = secondColor,
    )

    fun deleteFolder(id: Long) = folderQueries.delete(folder_id = id)

    fun updateFolder(
        id: Long,
        name: String,
        iconName: String? = null,
        firstColor: String? = null,
        secondColor: String? = null,
    ) = folderQueries.update(
        folder_id = id,
        name = name,
        iconName = iconName,
        firstColor = firstColor,
        secondColor = secondColor,
    )
    // endregion FOLDER

    // region TAG
    private val tagQueries = database.tagEntityQueries
    fun getAllTags() = tagQueries
        .getAll()
        .asFlow()
        .flowOn(Dispatchers.IO)
        .mapToList(Dispatchers.IO)

    fun createTag(
        name: String,
        iconName: String? = null,
        firstColor: String? = null,
        secondColor: String? = null,
    ) = tagQueries.create(
        name = name,
        iconName = iconName,
        firstColor = firstColor,
        secondColor = secondColor,
    )

    fun deleteTag(id: Long) = tagQueries.delete(tag_id = id)

    fun updateTag(
        id: Long,
        name: String,
        iconName: String? = null,
        firstColor: String? = null,
        secondColor: String? = null,
    ) = tagQueries.update(
        tag_id = id,
        name = name,
        iconName = iconName,
        firstColor = firstColor,
        secondColor = secondColor,
    )
    // endregion TAG
}
