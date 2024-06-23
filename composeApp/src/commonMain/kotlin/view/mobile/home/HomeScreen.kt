package view.mobile.home

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.AddCircleOutline
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.settings.localization.LocalizationStateProvider
import state.creation.CreateOrEditContentStateMachineProvider
import state.home.HomeState
import view.mobile.home.components.HomeAppBar
import view.mobile.home.components.HomeFAB
import view.mobile.home.components.HomeScreenGridContent

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    state: HomeState,
    modifier: Modifier = Modifier,
    onClickSearch: () -> Unit,
    onClickSync: () -> Unit,
    onClickSettings: () -> Unit,
) {
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current
    val localizationProvider = LocalizationStateProvider.current

    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    var shouldExtendFAB by remember { mutableStateOf(false) }

    YabaScaffold(
        modifier = modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            HomeAppBar(
                scrollBehavior = scrollBehavior,
                onClickSearch = onClickSearch,
                onClickSync = onClickSync,
                onClickSettings = onClickSettings,
            )
        },
        floatingActionButton = {
            HomeFAB(
                extended = shouldExtendFAB,
                onClickMaster = { shouldExtendFAB = shouldExtendFAB.not() },
                onDismissRequest = { shouldExtendFAB = false },
                onClickCreateBookmark = {
                    shouldExtendFAB = false
                    createOrEditContentStateMachine?.onShowBookmarkContent()
                },
                onClickCreateFolder = {
                    shouldExtendFAB = false
                    createOrEditContentStateMachine?.onShowFolderContent()
                },
                onClickCreateTag = {
                    shouldExtendFAB = false
                    createOrEditContentStateMachine?.onShowTagContent()
                },
            )
        }
    ) { paddings ->
        if (state.folders.isEmpty() && state.tags.isEmpty()) {
            YabaNoContentLayout(
                modifier = Modifier
                    .padding(paddings)
                    .padding(bottom = 56.dp),
                label = localizationProvider.localization.NO_CONTENT_HOME_LABEL,
                message = localizationProvider.localization.NO_CONTENT_HOME_MESSAGE,
                icon = Icons.TwoTone.AddCircleOutline,
                iconDescription = localizationProvider.accessibility.NO_CONTENT_HOME_ICON_DESCRIPTION,
            )
        } else {
            HomeScreenGridContent(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddings)
                    .padding(horizontal = 16.dp),
                state = state,
            )
        }
    }
}
