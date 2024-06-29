package state.manager

sealed class DatasourceCRUDEvent {

    // region FOLDER
    data class GetFolderCRUDEvent(
        val id: Long,
    ): DatasourceCRUDEvent()

    data object OnResetFolderState: DatasourceCRUDEvent()

    data class CreateFolderCRUDEvent(
        val name: String,
        val icon: String? = null,
        val firstColor: String? = null,
        val secondColor: String? = null,
    ): DatasourceCRUDEvent()

    data class EditFolderCRUDEvent(
        val folderId: Long,
        val name: String,
        val icon: String? = null,
        val firstColor: String? = null,
        val secondColor: String? = null,
    ): DatasourceCRUDEvent()

    data class DeleteFolderCRUDEvent(
        val id: Long,
    ): DatasourceCRUDEvent()
    // endregion FOLDER

    // region TAG
    data class GetTagCRUDEvent(
        val id: Long,
    ): DatasourceCRUDEvent()

    data object OnResetTagState: DatasourceCRUDEvent()

    data class CreateTagCRUDEvent(
        val name: String,
        val icon: String? = null,
        val firstColor: String? = null,
        val secondColor: String? = null,
    ): DatasourceCRUDEvent()

    data class EditTagCRUDEvent(
        val tagId: Long,
        val name: String,
        val icon: String? = null,
        val firstColor: String? = null,
        val secondColor: String? = null,
    ): DatasourceCRUDEvent()
    // endregion TAG
}