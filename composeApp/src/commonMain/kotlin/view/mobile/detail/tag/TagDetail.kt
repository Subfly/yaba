package view.mobile.detail.tag

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.twotone.Label
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
import state.detail.tag.TagDetailStateMachine
import state.manager.DatasourceCRUDEvent
import state.manager.DatasourceCRUDManagerProvider
import view.mobile.detail.components.DetailContent

@Composable
fun TagDetail(
    tagId: Long,
    tagName: String,
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
) {
    val contentState = ContentStateProvider.current
    val crudManager = DatasourceCRUDManagerProvider.current
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current

    val stateMachine = koinViewModel<TagDetailStateMachine>()
    val state by stateMachine.state.collectAsState()

    val currentTag by remember(contentState) {
        derivedStateOf {
            contentState.tags.fastFirstOrNull { it.id == tagId }
        }
    }

    LaunchedEffect(Unit) {
        stateMachine.fetchBookmarks(tagId = tagId)
    }

    DetailContent(
        modifier = modifier,
        title = currentTag?.name ?: tagName,
        bookmarks = state.bookmarks,
        isLoading = state.isLoading,
        appBarFirstColor = currentTag?.firstColor?.color ?: Color.Transparent,
        appBarSecondColor = currentTag?.secondColor?.color ?: Color.Transparent,
        appBarIcon = currentTag?.icon?.icon ?: Icons.AutoMirrored.TwoTone.Label,
        appBarIconDescription = currentTag?.icon?.name ?: Icons.AutoMirrored.TwoTone.Label.name,
        onClickBack = {
            stateMachine.dispose()
            onClickBack.invoke()
        },
        onClickEditOption = {
            createOrEditContentStateMachine?.onShowTagContent(
                tagId = tagId,
            )
        },
        onClickDeleteOption = {
            onClickBack.invoke()
            crudManager?.onEvent(
                event = DatasourceCRUDEvent.DeleteTagCRUDEvent(
                    id = tagId,
                )
            )
        },
    )
}
