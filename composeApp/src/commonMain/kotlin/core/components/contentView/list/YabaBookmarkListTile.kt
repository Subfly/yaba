package core.components.contentView.list

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
import androidx.compose.material.icons.twotone.ChevronRight
import androidx.compose.material.icons.twotone.Delete
import androidx.compose.material.icons.twotone.Edit
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastFirstOrNull
import coil3.compose.SubcomposeAsyncImage
import core.components.button.YabaTag
import core.components.layout.YabaCard
import core.model.TagModel
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.selections.ColorSelection
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.datetime.LocalDateTime
import state.content.ContentStateProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun YabaBookmarkListTile(
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
    onDeleteSwipe: () -> Unit,
    onEditSwipe: () -> Unit,
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
                if (index <= 5) {
                    filteredTags.add(tag)
                }
            }
            filteredTags.toList()
        }
    }

    var isSuccess by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()
    val annotatedTitle = buildAnnotatedString {
        append(title.first().toString())
    }

    val dismissState = rememberSwipeToDismissBoxState(
        initialValue = SwipeToDismissBoxValue.Settled,
        positionalThreshold = { it * 0.5f },
        confirmValueChange = { state ->
            when (state) {
                SwipeToDismissBoxValue.StartToEnd -> {
                    if (isInCreateOrEditMode.not()) {
                        scope.launch {
                            delay(250)
                            onEditSwipe.invoke()
                        }
                    }
                }

                SwipeToDismissBoxValue.EndToStart -> {
                    if (isInCreateOrEditMode.not()) {
                        scope.launch {
                            delay(250)
                            onDeleteSwipe.invoke()
                        }
                    }
                }

                SwipeToDismissBoxValue.Settled -> return@rememberSwipeToDismissBoxState false
            }
            return@rememberSwipeToDismissBoxState true
        }
    )

    SwipeToDismissBox(
        modifier = modifier.fillMaxWidth(),
        state = dismissState,
        backgroundContent = { BackgroundContent(dismissState) },
        enableDismissFromEndToStart = isInCreateOrEditMode.not(),
        enableDismissFromStartToEnd = isInCreateOrEditMode.not(),
    ) {
        YabaCard(
            modifier = Modifier.fillMaxWidth(),
            requireBorder = true,
            customBorderBrushColors = listOf(
                parentFolder?.firstColor?.color
                    ?: ColorSelection.PRIMARY.color,
                parentFolder?.secondColor?.color
                    ?: ColorSelection.SECONDARY.color,
            ),
            onClick = {
                if (isInCreateOrEditMode.not()) {
                    onClickBookmark.invoke()
                }
            },
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Row(
                    modifier = Modifier.weight(0.9f),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    SubcomposeAsyncImage(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .height(
                                if (tagsToUse.isNotEmpty()) 96.dp else 72.dp
                            )
                            .weight(0.2f),
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
                    Column(
                        modifier = Modifier.weight(0.8f),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                        horizontalAlignment = Alignment.Start,
                    ) {
                        Text(
                            text = title,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Text(
                            modifier = Modifier.padding(bottom = 4.dp),
                            text = description,
                            style = MaterialTheme.typography.bodyMedium,
                            maxLines = 1,
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
                                if (tags.size > 3) {
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
                    }
                }
                Icon(
                    modifier = Modifier
                        .weight(0.1f)
                        .clickable(onClick = onClickBookmark),
                    imageVector = Icons.TwoTone.ChevronRight,
                    contentDescription = localizationProvider.accessibility.OPEN_CONTENT_DESCRIPTION,
                    tint = themeState.colors.onBackground,
                )
            }
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BackgroundContent(dismissBoxState: SwipeToDismissBoxState) {
    val themeState = ThemeStateProvider.current
    val localizationState = LocalizationStateProvider.current

    val color = when (dismissBoxState.dismissDirection) {
        SwipeToDismissBoxValue.StartToEnd -> themeState.colors.primary
        SwipeToDismissBoxValue.EndToStart -> themeState.colors.secondary
        SwipeToDismissBoxValue.Settled -> Color.Transparent
    }

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(
                color = color,
                shape = RoundedCornerShape(8.dp)
            )
            .padding(
                horizontal = 12.dp,
                vertical = 8.dp,
            ),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Icon(
            imageVector = Icons.TwoTone.Edit,
            contentDescription = localizationState.accessibility.DELETE_ICON_DESCRIPTION,
            tint = themeState.colors.onPrimary,
        )
        Icon(
            imageVector = Icons.TwoTone.Delete,
            contentDescription = localizationState.accessibility.EDIT_ICON_DESCRIPTION,
            tint = themeState.colors.onSecondary,
        )
    }
}
