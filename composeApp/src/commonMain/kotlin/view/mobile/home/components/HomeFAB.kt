package view.mobile.home.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Add
import androidx.compose.material.icons.twotone.BookmarkAdd
import androidx.compose.material.icons.twotone.CreateNewFolder
import androidx.compose.material.icons.twotone.NewLabel
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.IntOffset
import core.components.button.YabaFab
import core.settings.localization.LocalizationStateProvider

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
        Box(contentAlignment = Alignment.Center) {
            InnerMiniFabContent(
                icon = Icons.TwoTone.BookmarkAdd,
                iconDescription = localizationProvider.accessibility.CREATE_BOOKMARK_ICON_DESCRIPTION,
                contentOffset = (animateMiniFabsTransition * 2.6f),
                onClick = onClickCreateBookmark,
            )
            InnerMiniFabContent(
                icon = Icons.TwoTone.CreateNewFolder,
                iconDescription = localizationProvider.accessibility.CREATE_FOLDER_ICON_DESCRIPTION,
                contentOffset = (animateMiniFabsTransition * 1.8f),
                onClick = onClickCreateFolder,
            )
            InnerMiniFabContent(
                icon = Icons.TwoTone.NewLabel,
                iconDescription = localizationProvider.accessibility.CREATE_TAG_ICON_DESCRIPTION,
                contentOffset = animateMiniFabsTransition,
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
    contentOffset: Float,
    icon: ImageVector,
    iconDescription: String,
    onClick: () -> Unit,
) {
    YabaFab(
        modifier = Modifier.offset {
            IntOffset(y = contentOffset.toInt(), x = 0)
        },
        isMini = true,
        onClick = onClick,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = iconDescription,
        )
    }

}
