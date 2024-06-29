package view.mobile.creation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import core.components.layout.YabaModalSheet
import state.creation.CreateOrEditContentStateMachineProvider
import state.manager.DatasourceCRUDEvent
import state.manager.DatasourceCRUDManagerProvider
import view.mobile.creation.components.CreateOrEditBookmarkContent
import view.mobile.creation.components.CreateOrEditFolderContent
import view.mobile.creation.components.CreateOrEditTagContent

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateOrEditContentSheet(modifier: Modifier = Modifier) {
    val stateMachine = CreateOrEditContentStateMachineProvider.current
    val crudManager = DatasourceCRUDManagerProvider.current
    val state = stateMachine?.state?.collectAsState()

    val createOrEditBookmarkSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val createOrEditFolderSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val createOrEditTagSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    Box(modifier = modifier.fillMaxSize()) {
        if (state?.value?.shouldShowCreateBookmarkSheet == true) {
            YabaModalSheet(
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.95f),
                sheetState = createOrEditBookmarkSheetState,
                onDismissRequest = {
                    stateMachine.onDismissBookmarkContent()
                },
            ) {
                CreateOrEditBookmarkContent(
                    modifier = Modifier.padding(16.dp),
                )
            }
        }
        if (state?.value?.shouldShowCreateFolderSheet == true) {
            YabaModalSheet(
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.95f),
                sheetState = createOrEditFolderSheetState,
                onDismissRequest = {
                    stateMachine.onDismissFolderContent()
                    crudManager?.onEvent(
                        event = DatasourceCRUDEvent.OnResetFolderState,
                    )
                },
            ) {
                CreateOrEditFolderContent(
                    modifier = Modifier.padding(16.dp),
                    folderId = state.value.editingFolderId,
                    onCreate = { name, icon, firstColor, secondColor ->
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.CreateFolderCRUDEvent(
                                name = name,
                                icon = icon,
                                firstColor = firstColor,
                                secondColor = secondColor,
                            )
                        )
                        stateMachine.onDismissFolderContent()
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.OnResetFolderState,
                        )
                    },
                    onEdit = { id, name, icon, firstColor, secondColor ->
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.EditFolderCRUDEvent(
                                folderId = id,
                                name = name,
                                icon = icon,
                                firstColor = firstColor,
                                secondColor = secondColor,
                            )
                        )
                        stateMachine.onDismissFolderContent()
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.OnResetFolderState,
                        )
                    }
                )
            }
        }
        if (state?.value?.shouldShowCreateTagSheet == true) {
            YabaModalSheet(
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.95f),
                sheetState = createOrEditTagSheetState,
                onDismissRequest = {
                    stateMachine.onDismissTagContent()
                    crudManager?.onEvent(
                        event = DatasourceCRUDEvent.OnResetTagState,
                    )
                },
            ) {
                CreateOrEditTagContent(
                    modifier = Modifier.padding(16.dp),
                    tagId = state.value.editingTagId,
                    onCreate = { name, icon, firstColor, secondColor ->
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.CreateTagCRUDEvent(
                                name = name,
                                icon = icon,
                                firstColor = firstColor,
                                secondColor = secondColor,
                            )
                        )
                        stateMachine.onDismissTagContent()
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.OnResetTagState,
                        )
                    },
                    onEdit = { id, name, icon, firstColor, secondColor ->
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.EditTagCRUDEvent(
                                tagId = id,
                                name = name,
                                icon = icon,
                                firstColor = firstColor,
                                secondColor = secondColor,
                            )
                        )
                        stateMachine.onDismissTagContent()
                        crudManager?.onEvent(
                            event = DatasourceCRUDEvent.OnResetTagState,
                        )
                    }
                )
            }
        }
    }
}
