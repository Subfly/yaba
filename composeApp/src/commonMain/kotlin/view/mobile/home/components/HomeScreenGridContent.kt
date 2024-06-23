package view.mobile.home.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridItemSpan
import androidx.compose.foundation.lazy.staggeredgrid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.CreateNewFolder
import androidx.compose.material.icons.twotone.NewLabel
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import core.components.button.YabaTag
import core.components.contentView.grid.YabaFolderGridItem
import core.components.layout.YabaNoContentLayout
import core.settings.localization.LocalizationStateProvider
import state.home.HomeState
import state.manager.DatasourceCUDManagerProvider

@OptIn(ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
fun HomeScreenGridContent(
    state: HomeState,
    modifier: Modifier = Modifier,
) {
    val localizationProvider = LocalizationStateProvider.current
    val datasourceCUDManager = DatasourceCUDManagerProvider.current

    var shouldExtendFolders by remember { mutableStateOf(true) }
    var shouldExtendTags by remember { mutableStateOf(true) }

    LazyVerticalStaggeredGrid(
        modifier = modifier,
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
            if (state.tags.isEmpty()) {
                item(
                    span = StaggeredGridItemSpan.FullLine,
                ) {
                    YabaNoContentLayout(
                        label = localizationProvider.localization.NO_TAGS_HOME_LABEL,
                        message = localizationProvider.localization.NO_TAGS_HOME_MESSAGE,
                        icon = Icons.TwoTone.NewLabel,
                        iconDescription = localizationProvider.accessibility.NO_TAG_HOME_ICON_DESCRIPTION,
                        isFullscreen = false,
                    )
                }
            } else {
                item(
                    span = StaggeredGridItemSpan.FullLine,
                ) {
                    FlowRow(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        state.tags.forEach { tag ->
                            YabaTag(
                                modifier = Modifier.animateItemPlacement(),
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
        }
        item(span = StaggeredGridItemSpan.FullLine) {
            HomeTitle(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp)
                    .padding(top = if (shouldExtendTags) 16.dp else 0.dp),
                title = localizationProvider.localization.FOLDERS_TITLE,
                expanded = shouldExtendFolders,
                onClick = { shouldExtendFolders = it }
            )
        }
        if (shouldExtendFolders) {
            if (state.folders.isEmpty()) {
                item(
                    span = StaggeredGridItemSpan.FullLine,
                ) {
                    YabaNoContentLayout(
                        label = localizationProvider.localization.NO_FOLDERS_HOME_LABEL,
                        message = localizationProvider.localization.NO_FOLDERS_HOME_MESSAGE,
                        icon = Icons.TwoTone.CreateNewFolder,
                        iconDescription = localizationProvider.accessibility.NO_FOLDER_HOME_ICON_DESCRIPTION,
                        isFullscreen = false,
                    )
                }
            } else {
                items(
                    items = state.folders,
                    key = { it.id },
                ) { folder ->
                    YabaFolderGridItem(
                        modifier = Modifier.animateItemPlacement(),
                        folderId = folder.id,
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