package state.home

import core.model.FolderModel
import core.model.TagModel

// TODO: CREATE ERROR ENUMS
data class HomeState(
    val folders: List<FolderModel> = emptyList(),
    val tags: List<TagModel> = emptyList(),
    val loading: Boolean = true,
    val error: String = "",
)
