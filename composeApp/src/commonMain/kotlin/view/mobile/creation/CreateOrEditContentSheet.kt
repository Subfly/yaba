package view.mobile.creation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SheetState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import core.components.layout.YabaModalSheet
import core.util.extensions.koinViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import state.creation.CreateOrEditContentStateMachine
import state.creation.CreateOrEditContentStateMachineProvider
import state.manager.DatasourceCUDEvent
import state.manager.DatasourceCUDManagerProvider
import view.mobile.creation.components.CreateOrEditBookmarkContent
import view.mobile.creation.components.CreateOrEditFolderContent
import view.mobile.creation.components.CreateOrEditTagContent

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateOrEditContentSheet(modifier: Modifier = Modifier) {
    val stateMachine = CreateOrEditContentStateMachineProvider.current
    val datasourceCUDManager = DatasourceCUDManagerProvider.current
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
                },
            ) {
                CreateOrEditFolderContent(
                    modifier = Modifier.padding(16.dp),
                    onCreate = { name, icon, firstColor, secondColor ->
                        datasourceCUDManager?.onEvent(
                            event = DatasourceCUDEvent.CreateFolderCUDEvent(
                                name = name,
                                icon = icon,
                                firstColor = firstColor,
                                secondColor = secondColor,
                            )
                        )
                        stateMachine.onDismissFolderContent()
                    },
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
                },
            ) {
                CreateOrEditTagContent(
                    modifier = Modifier.padding(16.dp),
                    onCreate = { name, icon, firstColor, secondColor ->
                        datasourceCUDManager?.onEvent(
                            event = DatasourceCUDEvent.CreateTagCUDEvent(
                                name = name,
                                icon = icon,
                                firstColor = firstColor,
                                secondColor = secondColor,
                            )
                        )
                        stateMachine.onDismissTagContent()
                    },
                )
            }
        }
    }
}
