package core.components.contentView.grid

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Add
import androidx.compose.material.icons.twotone.Delete
import androidx.compose.material.icons.twotone.Edit
import androidx.compose.material.icons.twotone.MoreVert
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastFirstOrNull
import coil3.compose.SubcomposeAsyncImage
import core.components.button.YabaTag
import core.components.layout.YabaCard
import core.components.layout.YabaMenu
import core.components.layout.YabaMenuItem
import core.model.TagModel
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.extensions.toUIString
import core.util.selections.ColorSelection
import kotlinx.datetime.LocalDateTime
import state.content.ContentStateProvider

@Composable
fun YabaBookmarkCard(
    modifier: Modifier = Modifier,
    title: String,
    description: String,
    parentFolderId: Long,
    dateAdded: LocalDateTime,
    tags: List<TagModel>,
    isPrivate: Boolean,
    imageUrl: String?,
    isInCreateOrEditMode: Boolean = false,
    onClickBookmark: () -> Unit,
) {
    val contentState = ContentStateProvider.current
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    val parentFolder by remember(parentFolderId) {
        derivedStateOf {
            contentState.folders.fastFirstOrNull { it.id == parentFolderId }
        }
    }

    val tagsToUse by remember(tags) {
        derivedStateOf {
            val filteredTags = mutableListOf<TagModel>()
            tags.forEachIndexed { index, tag ->
                if (index <= 3) {
                    filteredTags.add(tag)
                }
            }
            filteredTags.toList()
        }
    }

    var isSuccess by remember { mutableStateOf(false) }
    var isMenuExpanded by remember { mutableStateOf(false) }

    val annotatedTitle = buildAnnotatedString {
        val titleWords = title.split(" ")
        if (titleWords.size >= 2) {
            titleWords.forEachIndexed { index, char ->
                if (index < 2) {
                    append("${char.first()}. ")
                }
            }
        } else {
            if (title.length >= 2)
                append(
                    title.substring(startIndex = 0, endIndex = 2)
                )
            else
                title.first().toString()
        }
    }

    YabaCard(
        modifier = modifier,
        requireBorder = true,
        customBorderBrushColors = listOf(
            parentFolder?.firstColor?.color ?: ColorSelection.PRIMARY.color,
            parentFolder?.secondColor?.color ?: ColorSelection.SECONDARY.color,
        ),
        onClick = {
            if (isInCreateOrEditMode.not()) {
                onClickBookmark.invoke()
            }
        },
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(128.dp)
                    .clip(shape = RoundedCornerShape(8.dp))
            ) {
                // TODO: GET FROM ACCESSIBILITY
                SubcomposeAsyncImage(
                    modifier = Modifier
                        .fillMaxSize()
                        .align(Alignment.Center)
                        .clip(RoundedCornerShape(8.dp)),
                    model = imageUrl,
                    contentDescription = "Image",
                    contentScale = ContentScale.Crop,
                    filterQuality = FilterQuality.High,
                    onSuccess = { isSuccess = true },
                    onLoading = { isSuccess = false },
                    onError = { isSuccess = false },
                    loading = {
                        TitleImage(
                            title = annotatedTitle.text,
                            firstColor = parentFolder?.firstColor?.color
                                ?: themeState.colors.primary,
                            secondColor = parentFolder?.secondColor?.color
                                ?: themeState.colors.secondary,
                        )
                    },
                    error = {
                        TitleImage(
                            title = annotatedTitle.text,
                            firstColor = parentFolder?.firstColor?.color
                                ?: themeState.colors.primary,
                            secondColor = parentFolder?.secondColor?.color
                                ?: themeState.colors.secondary,
                        )
                    }
                )
                Box(
                    modifier = Modifier
                        .padding(
                            end = 12.dp,
                            top = 12.dp,
                        )
                        .align(Alignment.TopEnd),
                ) {
                    Icon(
                        modifier = Modifier
                            .clickable {
                                if (isInCreateOrEditMode.not()) {
                                    isMenuExpanded = true
                                }
                            }
                            .then(
                                if (isSuccess) {
                                    Modifier
                                        .graphicsLayer(alpha = 0.99f)
                                        .drawWithCache {
                                            onDrawWithContent {
                                                drawContent()
                                                drawRect(
                                                    Brush.linearGradient(
                                                        colors = listOf(
                                                            parentFolder?.firstColor?.color
                                                                ?: themeState.colors.primary,
                                                            parentFolder?.secondColor?.color
                                                                ?: themeState.colors.secondary,
                                                        )
                                                    ),
                                                    blendMode = BlendMode.SrcAtop,
                                                )
                                            }
                                        }
                                } else {
                                    Modifier
                                }
                            ),
                        imageVector = Icons.TwoTone.MoreVert,
                        contentDescription = localizationProvider.accessibility.SHOW_MORE_ICON_DESCRIPTION,
                        tint = themeState.colors.onBackground,
                    )
                    OptionsMenu(
                        isExpanded = isMenuExpanded,
                        onDismissRequest = {
                            isMenuExpanded = false
                        },
                        onClickDelete = {
                            isMenuExpanded = false
                            // TODO: DELETE FOLDER
                        },
                        onClickEdit = {
                            isMenuExpanded = false
                            // TODO: EDIT FOLDER
                        }
                    )
                }
            }
            Text(
                text = title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            if (tagsToUse.isNotEmpty()) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(2.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    tagsToUse.forEach { tag ->
                        YabaTag(
                            selected = true,
                            name = null,
                            icon = tag.icon?.icon,
                            iconDescription = tag.icon?.name,
                            firstColor = tag.firstColor?.color,
                            secondColor = tag.secondColor?.color,
                            onClick = {
                                // TODO: NAVIGATE TO TAG
                            },
                        )
                    }
                    if (tags.size > 4) {
                        YabaTag(
                            selected = false,
                            name = null,
                            icon = Icons.TwoTone.Add,
                            iconDescription = Icons.TwoTone.Add.name,
                            firstColor = null,
                            secondColor = null,
                            onClick = {},
                        )
                    }
                }
            }
            Text(
                text = dateAdded.toUIString(),
                style = MaterialTheme.typography.bodySmall,
                fontStyle = FontStyle.Italic,
            )
        }
    }
}

@Composable
private fun TitleImage(
    title: String,
    firstColor: Color,
    secondColor: Color,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(firstColor, secondColor)
                ),
                shape = RoundedCornerShape(8.dp),
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun OptionsMenu(
    isExpanded: Boolean,
    modifier: Modifier = Modifier,
    onDismissRequest: () -> Unit,
    onClickEdit: () -> Unit,
    onClickDelete: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    YabaMenu(
        modifier = modifier,
        expanded = isExpanded,
        onDismissRequest = onDismissRequest,
    ) {
        YabaMenuItem(
            text = {
                Text(localizationProvider.localization.EDIT_TITLE)
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.TwoTone.Edit,
                    contentDescription = localizationProvider.accessibility.EDIT_ICON_DESCRIPTION,
                )
            },
            onClick = onClickEdit,
        )
        YabaMenuItem(
            text = {
                Text(localizationProvider.localization.DELETE_TITLE)
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.TwoTone.Delete,
                    contentDescription = localizationProvider.accessibility.DELETE_ICON_DESCRIPTION,
                )
            },
            onClick = onClickDelete,
        )
    }
}
