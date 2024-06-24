package state.manager

sealed class DatasourceCRUDEvent {
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

    data class CreateTagCRUDEvent(
        val name: String,
        val icon: String? = null,
        val firstColor: String? = null,
        val secondColor: String? = null,
    ): DatasourceCRUDEvent()
}