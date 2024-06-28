package view.mobile.creation.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.twotone.LabelOff
import androidx.compose.material.icons.twotone.Clear
import androidx.compose.material.icons.twotone.NewLabel
import androidx.compose.material.icons.twotone.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.button.YabaElevatedButton
import core.components.button.YabaTag
import core.components.layout.YabaModalSheet
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.components.layout.YabaTextField
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import state.content.ContentStateProvider

@OptIn(
    ExperimentalLayoutApi::class,
    ExperimentalMaterial3Api::class,
)
@Composable
fun SelectTagsContent(
    alreadySelectedTags: List<Long>,
    sheetState: SheetState,
    modifier: Modifier = Modifier,
    onDismissRequest: () -> Unit,
    onTagsSelected: (List<Long>) -> Unit,
) {
    val contentState = ContentStateProvider.current
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    var query by remember { mutableStateOf("") }

    val selectedTagIds = remember {
        val ids = mutableStateListOf<Long>()
        ids.addAll(alreadySelectedTags)
        ids
    }
    val selectedTags = remember {
        derivedStateOf {
            contentState.tags.filter { it.id in selectedTagIds }
        }
    }
    val selectableTags = remember {
        derivedStateOf {
            if (selectedTagIds.isEmpty()) {
                if (query.isEmpty()) {
                    contentState.tags
                } else {
                    contentState.tags.filter {
                        it.name.lowercase().contains(query.trim().lowercase())
                    }
                }
            } else {
                if (query.isEmpty()) {
                    contentState.tags.filter { it.id !in selectedTagIds }
                } else {
                    contentState.tags.filter {
                        it.id !in selectedTagIds
                                && it.name.lowercase().contains(query.trim().lowercase())
                    }
                }
            }
        }
    }

    YabaModalSheet(
        modifier = modifier
            .fillMaxWidth()
            .fillMaxHeight(0.9f),
        sheetState = sheetState,
        onDismissRequest = onDismissRequest,
    ) {
        YabaScaffold(
            modifier = Modifier.fillMaxSize(),
            containerColor = themeState.colors.surface,
            contentColor = themeState.colors.onSurface,
            topBar = {
                SearchField(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    query = query,
                    onQueryChange = { query = it },
                    onClearPressed = { query = "" },
                )
            },
            bottomBar = {
                YabaElevatedButton(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp)
                        .padding(horizontal = 16.dp)
                        .height(56.dp),
                    onClick = {
                        onTagsSelected(selectedTagIds)
                    },
                ) {
                    Text(localizationProvider.localization.FINISH_TAG_SELECTION)
                }
            }
        ) { paddings ->
            if (contentState.tags.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(paddings),
                    contentAlignment = Alignment.Center,
                ) {
                    YabaNoContentLayout(
                        modifier = Modifier.align(Alignment.Center),
                        label = localizationProvider.localization.NO_TAGS_SELECT_TAGS_LABEL,
                        message = localizationProvider.localization.NO_TAGS_SELECT_TAGS_MESSAGE,
                        icon = Icons.TwoTone.NewLabel,
                        iconDescription = localizationProvider.accessibility.NO_TAG_ICON_DESCRIPTION,
                        isFullscreen = true,
                    )
                }
            } else {
                LazyColumn(
                    modifier = modifier
                        .padding(paddings)
                        .padding(16.dp),
                ) {
                    item {
                        Text(
                            modifier = Modifier.padding(bottom = 8.dp),
                            text = localizationProvider.localization.SELECTED_TAGS_TITLE,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    if (selectedTags.value.isEmpty()) {
                        item {
                            YabaNoContentLayout(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 32.dp)
                                    .padding(bottom = 32.dp)
                                    .align(Alignment.CenterHorizontally),
                                label = localizationProvider.localization.NO_TAGS_SELECTED_SELECT_TAGS_LABEL,
                                message = localizationProvider.localization.NO_TAGS_SELECTED_SELECT_TAGS_MESSAGE,
                                icon = Icons.TwoTone.NewLabel,
                                iconDescription = localizationProvider.accessibility.NO_TAG_ICON_DESCRIPTION,
                                isFullscreen = false,
                            )
                        }
                    } else {
                        item {
                            FlowRow(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(bottom = 32.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                selectedTags.value.forEach { tag ->
                                    YabaTag(
                                        selected = true,
                                        name = tag.name,
                                        firstColor = tag.firstColor?.color,
                                        secondColor = tag.secondColor?.color,
                                        icon = tag.icon?.icon,
                                        iconDescription = tag.icon?.name,
                                        onClick = {
                                            selectedTagIds.remove(tag.id)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    item {
                        Text(
                            modifier = Modifier.padding(bottom = 8.dp),
                            text = localizationProvider.localization.SELECTABLE_TAGS_TITLE,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    if (selectableTags.value.isEmpty()) {
                        item {
                            YabaNoContentLayout(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 32.dp)
                                    .align(Alignment.CenterHorizontally),
                                label = localizationProvider.localization.NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_LABEL,
                                message = if (query.isEmpty()) {
                                    localizationProvider.localization.NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_MESSAGE
                                } else {
                                    localizationProvider.localization.NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_FORMATTABLE_MESSAGE(
                                        query = query,
                                    )
                                },
                                icon = Icons.AutoMirrored.TwoTone.LabelOff,
                                iconDescription = localizationProvider.accessibility.NO_TAG_ICON_DESCRIPTION,
                                isFullscreen = false,
                            )
                        }
                    } else {
                        item {
                            FlowRow(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(8.dp),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                selectableTags.value.forEach { tag ->
                                    YabaTag(
                                        selected = false,
                                        name = tag.name,
                                        firstColor = tag.firstColor?.color,
                                        secondColor = tag.secondColor?.color,
                                        icon = tag.icon?.icon,
                                        iconDescription = tag.icon?.name,
                                        onClick = {
                                            selectedTagIds.add(tag.id)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SearchField(
    query: String,
    modifier: Modifier = Modifier,
    onQueryChange: (String) -> Unit,
    onClearPressed: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    YabaTextField(
        modifier = modifier.fillMaxWidth(),
        value = query,
        onValueChange = onQueryChange,
        singleLine = true,
        placeholder = {
            Text(localizationProvider.localization.SEARCH_FIELD_PLACEHOLDER)
        },
        leadingIcon = {
            Icon(
                imageVector = Icons.TwoTone.Search,
                contentDescription = localizationProvider.accessibility.SEARCH_ICON_DESCIPTION,
            )
        },
        trailingIcon = {
            Icon(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .clickable(onClick = onClearPressed),
                imageVector = Icons.TwoTone.Clear,
                contentDescription = localizationProvider.accessibility.CLEAR_SEARCH_FIELD_ICON_DESCRIPTION,
            )
        }
    )
}
