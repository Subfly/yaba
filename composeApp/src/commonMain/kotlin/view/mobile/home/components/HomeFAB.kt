package view.mobile.home.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Add
import androidx.compose.material.icons.twotone.BookmarkAdd
import androidx.compose.material.icons.twotone.CreateNewFolder
import androidx.compose.material.icons.twotone.NewLabel
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import core.components.button.YabaFab
import core.localization.LocalizationStateProvider

@Composable
fun HomeFAB(
    extended: Boolean,
    modifier: Modifier = Modifier,
    onClickMaster: () -> Unit,
    onClickCreateBookmark: () -> Unit,
    onClickCreateFolder: () -> Unit,
    onClickCreateTag: () -> Unit,
    onDismissRequest: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    val animateMasterFabTransition by animateFloatAsState(
        targetValue = if (extended) -45f else 0f,
    )
    val animateMiniFabsTransition by animateFloatAsState(
        targetValue = if (extended) -175f else 0f,
        animationSpec = spring(),
    )
    val animateTextAlpha by animateFloatAsState(
        targetValue = if (extended) 1f else 0f,
    )

    var createBookmarkTextOffset by remember { mutableStateOf(0) }
    var createFolderTextOffset by remember { mutableStateOf(0) }
    var createTagTextOffset by remember { mutableStateOf(0) }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.BottomEnd,
    ) {
        if (extended) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                        onClick = onDismissRequest,
                    )
            )
        }
        Box(
            modifier = Modifier
                .offset {
                    IntOffset(
                        x = createBookmarkTextOffset / 3,
                        y = 0
                    )
                },
            contentAlignment = Alignment.Center
        ) {
            InnerMiniFabContent(
                text = localizationProvider.localization.CREATE_BOOKMARK,
                icon = Icons.TwoTone.BookmarkAdd,
                iconDescription = localizationProvider.accessibility.CREATE_BOOKMARK_ICON_DESCRIPTION,
                contentOffset = (animateMiniFabsTransition * 2.6f),
                textOffset = (50 - createBookmarkTextOffset),
                textAlpha = animateTextAlpha,
                onTextLayout = { createBookmarkTextOffset = it },
                onClick = onClickCreateBookmark,
            )
            InnerMiniFabContent(
                text = localizationProvider.localization.CREATE_FOLDER,
                icon = Icons.TwoTone.CreateNewFolder,
                iconDescription = localizationProvider.accessibility.CREATE_FOLDER_ICON_DESCRIPTION,
                contentOffset = (animateMiniFabsTransition * 1.8f),
                textOffset = 60 - createFolderTextOffset,
                textAlpha = animateTextAlpha,
                onTextLayout = { createFolderTextOffset = it },
                onClick = onClickCreateFolder,
            )
            InnerMiniFabContent(
                text = localizationProvider.localization.CREATE_TAG,
                icon = Icons.TwoTone.NewLabel,
                iconDescription = localizationProvider.accessibility.CREATE_TAG_ICON_DESCRIPTION,
                contentOffset = animateMiniFabsTransition,
                textOffset = 50 - createTagTextOffset,
                textAlpha = animateTextAlpha,
                onTextLayout = { createTagTextOffset = it },
                onClick = onClickCreateTag,
            )
            YabaFab(
                modifier = modifier,
                onClick = onClickMaster,
            ) {
                Icon(
                    modifier = Modifier.rotate(animateMasterFabTransition),
                    imageVector = Icons.TwoTone.Add,
                    contentDescription = localizationProvider.accessibility.CREATE_CONTENT_ICON_DESCRIPTION,
                )
            }
        }
    }
}

@Composable
private fun InnerMiniFabContent(
    text: String,
    icon: ImageVector,
    iconDescription: String,
    contentOffset: Float,
    textOffset: Int,
    textAlpha: Float,
    modifier: Modifier = Modifier,
    onTextLayout: (Int) -> Unit,
    onClick: () -> Unit,
) {
    Box(
        modifier = modifier.offset {
            IntOffset(y = contentOffset.toInt(), x = 0)
        },
        contentAlignment = Alignment.Center,
    ) {
        Text(
            modifier = Modifier
                .offset { IntOffset(x = textOffset, y = 0) }
                .alpha(textAlpha),
            text = text,
            onTextLayout = { onTextLayout(it.size.width) },
        )
        YabaFab(
            isMini = true,
            onClick = onClick,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = iconDescription,
            )
        }
    }
}
