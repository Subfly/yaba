package view.mobile.creation.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.twotone.Help
import androidx.compose.material.icons.twotone.Add
import androidx.compose.material.icons.twotone.Description
import androidx.compose.material.icons.twotone.Link
import androidx.compose.material.icons.twotone.NewLabel
import androidx.compose.material.icons.twotone.Title
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.util.fastFilter
import androidx.compose.ui.util.fastFirstOrNull
import core.components.button.YabaElevatedButton
import core.components.button.YabaIconButton
import core.components.button.YabaTag
import core.components.contentView.grid.YabaBookmarkCard
import core.components.contentView.list.YabaBookmarkListTile
import core.components.contentView.list.YabaFolderListTile
import core.components.layout.YabaNoContentLayout
import core.components.layout.YabaScaffold
import core.components.layout.YabaTextField
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.extensions.isValidUrl
import core.util.selections.ContentViewSelection
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import state.content.ContentStateProvider
import unfurl.UnfurlingUtil
import unfurl.models.UnfurlModel

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
internal fun CreateOrEditBookmarkContent(modifier: Modifier = Modifier) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current
    val contentState = ContentStateProvider.current

    val folderSelectionSheetState = rememberModalBottomSheetState(
        skipPartiallyExpanded = true,
    )
    val tagsSelectionSheetState = rememberModalBottomSheetState(
        skipPartiallyExpanded = true,
    )

    var shouldShowFolderSelectionSheet by remember { mutableStateOf(false) }
    var shouldShowTagsSelectionSheet by remember { mutableStateOf(false) }

    var urlFieldValue by remember { mutableStateOf("") }
    var nameFieldValue by remember { mutableStateOf("") }
    var descriptionFieldValue by remember { mutableStateOf("") }
    var currentContentViewSelection by remember {
        mutableStateOf(ContentViewSelection.GRID)
    }
    var unfurlData: UnfurlModel by remember {
        mutableStateOf(UnfurlModel.None)
    }

    var selectedFolderId by remember { mutableStateOf(-1L) }
    val selectedFolder by remember(selectedFolderId) {
        derivedStateOf {
            contentState.folders.fastFirstOrNull { it.id == selectedFolderId }
        }
    }

    val selectedTagIds = remember { mutableStateListOf<Long>() }
    val selectedTags by remember(selectedTagIds) {
        derivedStateOf {
            contentState.tags.fastFilter { it.id in selectedTagIds }
        }
    }

    LaunchedEffect(urlFieldValue) {
        if (urlFieldValue.isNotEmpty() && urlFieldValue.isValidUrl()) {
            unfurlData = UnfurlingUtil.getUnfurledMetadata(urlFieldValue)
        }
    }

    Box(modifier = modifier) {
        YabaScaffold(
            containerColor = themeState.colors.surface,
            contentColor = themeState.colors.onSurface,
            bottomBar = {
                YabaElevatedButton(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp)
                        .height(56.dp),
                    onClick = {

                    },
                ) {
                    Text(localizationProvider.localization.CREATE_BOOKMARK)
                }
            }
        ) { paddings ->
            Column(
                modifier = Modifier
                    .padding(paddings)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(
                        localizationProvider.localization.PREVIEW,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        YabaIconButton(
                            onClick = {
                                currentContentViewSelection =
                                    if (currentContentViewSelection == ContentViewSelection.GRID) {
                                        ContentViewSelection.LIST
                                    } else {
                                        ContentViewSelection.GRID
                                    }
                            }
                        ) {
                            Icon(
                                imageVector = currentContentViewSelection.icon,
                                contentDescription = currentContentViewSelection.getDescription(
                                    accessibility = localizationProvider.accessibility,
                                ),
                                tint = themeState.colors.onBackground,
                            )
                        }
                        YabaIconButton(
                            onClick = {
                                // TODO: SHOW INFO
                            }
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.TwoTone.Help,
                                contentDescription = localizationProvider.accessibility.HELP_ICON_DESCRIPTION,
                                tint = themeState.colors.onBackground,
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.size(16.dp))
                when (currentContentViewSelection) {
                    ContentViewSelection.GRID -> {
                        YabaBookmarkCard(
                            modifier = Modifier.padding(horizontal = 100.dp),
                            title = if (nameFieldValue.isNotBlank()) {
                                nameFieldValue.trim()
                            } else {
                                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                                "Kayıt Adı"
                            },
                            description = if (descriptionFieldValue.isNotBlank()) {
                                descriptionFieldValue.trim()
                            } else {
                                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                                "Dosya Açıklaması (En fazla 3 satır gözükür)"
                            },
                            parentFolderId = selectedFolderId,
                            dateAdded = Clock.System.now().toLocalDateTime(
                                timeZone = TimeZone.currentSystemDefault(),
                            ),
                            tags = selectedTags,
                            isPrivate = false,
                            imageUrl = (unfurlData as? UnfurlModel.Success)?.twitterModel?.imageUrl,
                            isInCreateOrEditMode = true,
                            onClickBookmark = {},
                        )
                    }
                    ContentViewSelection.LIST -> {
                        YabaBookmarkListTile(
                            modifier = Modifier.fillMaxWidth(),
                            title = if (nameFieldValue.isNotBlank()) {
                                nameFieldValue.trim()
                            } else {
                                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                                "Kayıt Adı"
                            },
                            description = if (descriptionFieldValue.isNotBlank()) {
                                descriptionFieldValue.trim()
                            } else {
                                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                                "Dosya Açıklaması (En fazla 1 satır gözükür)"
                            },
                            parentFolderId = selectedFolderId,
                            dateAdded = Clock.System.now().toLocalDateTime(
                                timeZone = TimeZone.currentSystemDefault(),
                            ),
                            tags = selectedTags,
                            isPrivate = false,
                            imageUrl = (unfurlData as? UnfurlModel.Success)?.twitterModel?.imageUrl,
                            isInCreateOrEditMode = true,
                            onClickBookmark = {},
                            onEditSwipe = {},
                            onDeleteSwipe = {},
                        )
                    }
                }
                Spacer(modifier = Modifier.size(32.dp))
                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                Text(
                    text = "Kayıt Linki",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(modifier = Modifier.size(8.dp))
                YabaTextField(
                    modifier = Modifier.fillMaxWidth(),
                    value = urlFieldValue,
                    onValueChange = { urlFieldValue = it },
                    // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                    label = {
                        Text("Kayıt Linki")
                    },
                    placeholder = {
                        Text(localizationProvider.localization.WRITE_HERE)
                    },
                    leadingIcon = {
                        // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                        Icon(
                            imageVector = Icons.TwoTone.Link,
                            contentDescription = ""
                        )
                    }
                )
                Spacer(modifier = Modifier.size(16.dp))
                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                Text(
                    text = "Kayıt Adı",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(modifier = Modifier.size(8.dp))
                YabaTextField(
                    modifier = Modifier.fillMaxWidth(),
                    value = nameFieldValue,
                    onValueChange = { nameFieldValue = it },
                    // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                    label = {
                        Text("Kayıt Adı")
                    },
                    placeholder = {
                        Text(localizationProvider.localization.WRITE_HERE)
                    },
                    leadingIcon = {
                        // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                        Icon(
                            imageVector = Icons.TwoTone.Title,
                            contentDescription = ""
                        )
                    }
                )
                Spacer(modifier = Modifier.size(16.dp))
                Text(
                    text = "Kayıt Açıklaması",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(modifier = Modifier.size(8.dp))
                YabaTextField(
                    modifier = Modifier.fillMaxWidth(),
                    value = descriptionFieldValue,
                    onValueChange = { descriptionFieldValue = it },
                    // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                    label = {
                        Text("Kayıt Açıklaması")
                    },
                    placeholder = {
                        Text(localizationProvider.localization.WRITE_HERE)
                    },
                    leadingIcon = {
                        // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                        Icon(
                            imageVector = Icons.TwoTone.Description,
                            contentDescription = ""
                        )
                    }
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Kaydedilecek Dosya",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(modifier = Modifier.size(8.dp))
                YabaFolderListTile(
                    folderName = selectedFolder?.name
                        ?: localizationProvider.localization.OTHERS_FOLDER_NAME,
                    bookmarkCount = selectedFolder?.bookmarkCount ?: 0,
                    icon = selectedFolder?.icon?.icon,
                    iconDescription = selectedFolder?.icon?.name,
                    firstColor = selectedFolder?.firstColor?.color,
                    secondColor = selectedFolder?.secondColor?.color,
                    onClickFolder = { shouldShowFolderSelectionSheet = true },
                    isInCreateOrEditMode = true,
                    onEditSwipe = {},
                    onDeleteSwipe = {},
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = localizationProvider.localization.TAGS_TITLE,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(modifier = Modifier.size(8.dp))
                if (selectedTags.isEmpty()) {
                    YabaNoContentLayout(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 32.dp)
                            .align(Alignment.CenterHorizontally)
                            .clip(RoundedCornerShape(8.dp))
                            .clickable {
                                shouldShowTagsSelectionSheet = true
                            },
                        label = localizationProvider.localization.NO_TAGS_SELECTED_SELECT_TAGS_LABEL,
                        message = localizationProvider.localization.NO_TAGS_SELECTED_CLICK_HERE_SELECT_TAGS_LABEL,
                        icon = Icons.TwoTone.NewLabel,
                        iconDescription = localizationProvider.accessibility.NO_TAG_ICON_DESCRIPTION,
                        isFullscreen = false,
                    )
                } else {
                    FlowRow(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        YabaTag(
                            selected = false,
                            name = localizationProvider.localization.ADD_TAG,
                            firstColor = themeState.colors.primary,
                            secondColor = themeState.colors.secondary,
                            icon = Icons.TwoTone.Add,
                            iconDescription = Icons.TwoTone.Add.name,
                            onClick = { shouldShowTagsSelectionSheet = true },
                        )
                        selectedTags.forEach { tag ->
                            YabaTag(
                                selected = true,
                                name = tag.name,
                                firstColor = tag.firstColor?.color,
                                secondColor = tag.secondColor?.color,
                                icon = tag.icon?.icon,
                                iconDescription = tag.icon?.name,
                                onClick = {},
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.size(32.dp))
            }
        }
        if (shouldShowFolderSelectionSheet) {
            SelectFolderContent(
                sheetState = folderSelectionSheetState,
                onFolderSelected = {
                    selectedFolderId = it
                    shouldShowFolderSelectionSheet = false
                },
                onDismissRequest = {
                    shouldShowFolderSelectionSheet = false
                },
            )
        }
        if (shouldShowTagsSelectionSheet) {
            SelectTagsContent(
                alreadySelectedTags = selectedTagIds,
                sheetState = tagsSelectionSheetState,
                onTagsSelected = {
                    selectedTagIds.clear()
                    selectedTagIds.addAll(it)
                    shouldShowTagsSelectionSheet = false
                },
                onDismissRequest = {
                    shouldShowTagsSelectionSheet = false
                },
            )
        }
    }
}
