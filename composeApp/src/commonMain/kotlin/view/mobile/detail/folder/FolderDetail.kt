package view.mobile.detail.folder

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.util.fastFirstOrNull
import core.util.extensions.koinViewModel
import state.content.ContentStateProvider
import state.creation.CreateOrEditContentStateMachineProvider
import state.detail.folder.FolderDetailStateMachine
import state.manager.DatasourceCRUDEvent
import state.manager.DatasourceCRUDManagerProvider
import view.mobile.detail.components.DetailContent

@Composable
fun FolderDetail(
    folderId: Long,
    folderName: String,
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
) {
    val contentState = ContentStateProvider.current
    val crudManager = DatasourceCRUDManagerProvider.current
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current

    val stateMachine = koinViewModel<FolderDetailStateMachine>()
    val state by stateMachine.state.collectAsState()

    val currentFolder by remember(contentState) {
        derivedStateOf {
            contentState.folders.fastFirstOrNull { it.id == folderId }
        }
    }

    LaunchedEffect(Unit) {
        stateMachine.fetchBookmarks(folderId = folderId)
    }

    DetailContent(
        modifier = modifier,
        title = currentFolder?.name ?: folderName,
        bookmarks = state.bookmarks,
        isLoading = state.isLoading,
        appBarFirstColor = currentFolder?.firstColor?.color ?: Color.Transparent,
        appBarSecondColor = currentFolder?.secondColor?.color ?: Color.Transparent,
        onClickBack = {
            stateMachine.dispose()
            onClickBack.invoke()
        },
        onClickEditOption = {
            createOrEditContentStateMachine?.onShowFolderContent(
                folderId = folderId,
            )
        },
        onClickDeleteOption = {
            onClickBack.invoke()
            crudManager?.onEvent(
                event = DatasourceCRUDEvent.DeleteFolderCRUDEvent(
                    id = folderId,
                )
            )
        },
    )
}
