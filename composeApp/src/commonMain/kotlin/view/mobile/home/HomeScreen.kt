package view.mobile.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.AddCircleOutline
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.constants.GeneralConstants
import core.localization.LocalizationStateProvider
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import state.home.HomeState
import view.mobile.creation.CreateOrEditContentSheet
import view.mobile.creation.CreateOrEditContentType
import view.mobile.home.components.HomeAppBar
import view.mobile.home.components.HomeFAB

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    state: HomeState,
    modifier: Modifier = Modifier,
    onClickSearch: () -> Unit,
    onClickSync: () -> Unit,
    onClickSettings: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    var shouldExtendFAB by remember { mutableStateOf(false) }
    var shouldShowCreateBookmarkSheet by remember { mutableStateOf(false) }
    var currentSheetType by remember { mutableStateOf(CreateOrEditContentType.NONE) }

    val scope = rememberCoroutineScope()
    val createBookmarkSheetState = rememberModalBottomSheetState(
        skipPartiallyExpanded = true,
    )

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
                onClickMaster = {
                    shouldExtendFAB = shouldExtendFAB.not()
                },
                onDismissRequest = {
                    shouldExtendFAB = false
                },
                onClickCreateBookmark = {
                    scope.launch {
                        shouldExtendFAB = false
                        currentSheetType = CreateOrEditContentType.BOOKMARK
                        delay(GeneralConstants.MAGIC_THREE_FRAME_SKIP_DURATION)
                        shouldShowCreateBookmarkSheet = true
                    }
                },
                onClickCreateFolder = {
                    scope.launch {
                        shouldExtendFAB = false
                        currentSheetType = CreateOrEditContentType.FOLDER
                        delay(GeneralConstants.MAGIC_THREE_FRAME_SKIP_DURATION)
                        shouldShowCreateBookmarkSheet = true
                    }
                },
                onClickCreateTag = {
                    scope.launch {
                        shouldExtendFAB = false
                        currentSheetType = CreateOrEditContentType.TAG
                        delay(GeneralConstants.MAGIC_THREE_FRAME_SKIP_DURATION)
                        shouldShowCreateBookmarkSheet = true
                    }
                },
            )
        }
    ) { paddings ->
        YabaNoContentLayout(
            modifier = Modifier
                .padding(paddings)
                .padding(bottom = 56.dp),
            label = localizationProvider.localization.NO_CONTENT_HOME_LABEL,
            message = localizationProvider.localization.NO_CONTENT_HOME_MESSAGE,
            icon = Icons.TwoTone.AddCircleOutline,
            iconDescription = localizationProvider.accessibility.NO_CONTENT_HOME_ICON_DESCRIPTION,
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddings)
        ) {
            if (shouldShowCreateBookmarkSheet) {
                CreateOrEditContentSheet(
                    sheetType = currentSheetType,
                    sheetState = createBookmarkSheetState,
                    onDismissRequrest = {
                        scope.launch {
                            shouldShowCreateBookmarkSheet = false
                            delay(300)
                            currentSheetType = CreateOrEditContentType.NONE
                        }
                    }
                )
            }
        }
    }
}
