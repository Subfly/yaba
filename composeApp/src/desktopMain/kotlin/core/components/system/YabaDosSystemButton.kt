package core.components.system

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Close
import androidx.compose.material.icons.twotone.Fullscreen
import androidx.compose.material.icons.twotone.FullscreenExit
import androidx.compose.material.icons.twotone.Minimize
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.onPointerEvent
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import core.components.button.YabaIconButton
import core.settings.theme.ThemeStateProvider

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun YabaDosSystemButton(
    type: YabaSystemButtonType,
    isFullScreen: Boolean,
    onClick: () -> Unit,
) {
    val themeState = ThemeStateProvider.current
    var isMauseEnteredToSystemButtons by remember { mutableStateOf(false) }

    YabaIconButton(
        modifier = Modifier
            .size(36.dp)
            .onPointerEvent(PointerEventType.Enter) { isMauseEnteredToSystemButtons = true }
            .onPointerEvent(PointerEventType.Exit) { isMauseEnteredToSystemButtons = false },
        onClick = onClick,
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    color = if (isMauseEnteredToSystemButtons) {
                        when (type) {
                            YabaSystemButtonType.CLOSE -> themeState.colors.systemCloseColor
                            YabaSystemButtonType.MINIMZE -> if (isFullScreen)
                                themeState.colors.systemDisabledColor
                            else
                                themeState.colors.systemMinimizeColor

                            YabaSystemButtonType.FULLSCREEN -> themeState.colors.systemFullscreenColor
                        }.copy(alpha = 0.5f)
                    } else {
                        Color.Transparent
                    },
                ),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = when (type) {
                    YabaSystemButtonType.CLOSE -> Icons.TwoTone.Close
                    YabaSystemButtonType.MINIMZE -> Icons.TwoTone.Minimize
                    YabaSystemButtonType.FULLSCREEN -> if (isFullScreen)
                        Icons.TwoTone.FullscreenExit
                    else
                        Icons.TwoTone.Fullscreen
                },
                contentDescription = when (type) {
                    YabaSystemButtonType.CLOSE -> "Close Window"
                    YabaSystemButtonType.MINIMZE -> "Minimize Window"
                    YabaSystemButtonType.FULLSCREEN -> if (isFullScreen)
                        "Shrink Window"
                    else
                        "Maximize Window"
                },
                modifier = Modifier
                    .size(28.dp)
                    .offset {
                        if (type == YabaSystemButtonType.MINIMZE) {
                            IntOffset(
                                y = (-2.5).dp.toPx().toInt(),
                                x = 0,
                            )
                        } else {
                            IntOffset.Zero
                        }
                    },
                tint = themeState.colors.onBackground,
            )
        }
    }
}