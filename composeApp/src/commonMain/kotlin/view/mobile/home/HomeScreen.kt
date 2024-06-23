package view.mobile.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridItemSpan
import androidx.compose.foundation.lazy.staggeredgrid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.AddCircleOutline
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import core.components.button.YabaTag
import core.components.contentView.grid.YabaFolderGridItem
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.constants.GeneralConstants
import core.localization.LocalizationStateProvider
import core.util.icon.YabaIcons
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import state.creation.CreateOrEditContentStateMachineProvider
import state.home.HomeState
import view.mobile.creation.CreateOrEditContentSheet
import view.mobile.creation.CreateOrEditContentType
import view.mobile.home.components.HomeAppBar
import view.mobile.home.components.HomeFAB
import view.mobile.home.components.HomeTitle

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun HomeScreen(
    state: HomeState,
    modifier: Modifier = Modifier,
    onClickSearch: () -> Unit,
    onClickSync: () -> Unit,
    onClickSettings: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current
    val createOrEditContentStateMachine = CreateOrEditContentStateMachineProvider.current

    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    var shouldExtendFAB by remember { mutableStateOf(false) }
    var shouldExtendFolders by remember { mutableStateOf(true) }
    var shouldExtendTags by remember { mutableStateOf(true) }

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
            LazyVerticalStaggeredGrid(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddings)
                    .padding(horizontal = 16.dp),
                columns = StaggeredGridCells.Fixed(2),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalItemSpacing = 16.dp,
            ) {
                item(span = StaggeredGridItemSpan.FullLine) {
                    HomeTitle(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 16.dp),
                        title = localizationProvider.localization.TAGS_TITLE,
                        expanded = shouldExtendTags,
                        onClick = { shouldExtendTags = it }
                    )
                }
                if (shouldExtendTags) {
                    item {
                        FlowRow {
                            state.tags.forEach { tag ->
                                YabaTag(
                                    selected = true,
                                    name = tag.name,
                                    firstColor = tag.firstColor?.color,
                                    secondColor = tag.secondColor?.color,
                                    icon = tag.icon?.icon,
                                    iconDescription = tag.icon?.key,
                                    onClick = {
                                        // TODO: NAVIGATE TO TAG DETAIL
                                    }
                                )
                            }
                        }
                    }
                }
                item(span = StaggeredGridItemSpan.FullLine) {
                    HomeTitle(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 16.dp)
                            .padding(top = if (shouldExtendFolders) 16.dp else 0.dp),
                        title = localizationProvider.localization.FOLDERS_TITLE,
                        expanded = shouldExtendFolders,
                        onClick = { shouldExtendFolders = it }
                    )
                }
                if (shouldExtendFolders) {
                    items(
                        items = state.folders,
                        key = { it.id },
                    ) { folder ->
                        YabaFolderGridItem(
                            folderName = folder.name,
                            bookmarkCount = 0, // TODO: GET COUNT
                            icon = folder.icon?.icon,
                            iconDescription = folder.icon?.key,
                            firstColor = folder.firstColor?.color,
                            secondColor = folder.secondColor?.color,
                            onClickFolder = {
                                // TODO: NAVIGATE TO FOLDER DETAIL
                            }
                        )
                    }
                }
            }
        }
    }
}
