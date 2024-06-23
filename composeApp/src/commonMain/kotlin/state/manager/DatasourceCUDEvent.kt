package state.manager

sealed class DatasourceCUDEvent {
    data class CreateFolderCUDEvent(
        val name: String,
        val icon: String? = null,
        val firstColor: String? = null,
        val secondColor: String? = null,
    ): DatasourceCUDEvent()

    data class DeleteFolderCUDEvent(
        val id: Long,
    ): DatasourceCUDEvent()

    data class CreateTagCUDEvent(
        val name: String,
        val icon: String? = null,
        val firstColor: String? = null,
        val secondColor: String? = null,
    ): DatasourceCUDEvent()
}