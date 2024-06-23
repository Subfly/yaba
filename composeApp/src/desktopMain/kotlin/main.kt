import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.onClick
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.window.WindowDraggableArea
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.BookmarkAdd
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.onPointerEvent
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.*
import core.components.layout.YabaAppBar
import core.components.button.YabaFab
import core.components.button.YabaIconButton
import core.components.layout.YabaScaffold
import core.components.layout.YabaCard
import core.components.system.YabaDosSystemButton
import core.components.system.YabaNixSystemButton
import core.components.system.YabaSystemButtonType
import core.theme.components.YabaTheme
import di.DIHelper
import org.jetbrains.compose.resources.painterResource
import yaba.composeapp.generated.resources.Res
import yaba.composeapp.generated.resources.ic_left_panel

@OptIn(ExperimentalMaterial3Api::class, ExperimentalComposeUiApi::class, ExperimentalFoundationApi::class)
fun main() = application {
    DIHelper.initKoin()

    val state = rememberWindowState()
    var isMauseEnteredToSystemButtons by remember { mutableStateOf(false) }

    Window(
        title = "Yaba",
        state = state,
        onCloseRequest = ::exitApplication,
        undecorated = true,
        transparent = true,
    ) {
        YabaApp()
        /*
        WindowDraggableArea(
            modifier = Modifier.clip(shape = RoundedCornerShape(size = 12.dp))
        ) {
            YabaTheme {
                YabaScaffold(
                    modifier = Modifier.fillMaxSize(),
                    topBar = {
                        YabaAppBar(
                            modifier = Modifier.onClick(
                                onClick = {},
                                onDoubleClick = {
                                    if (state.placement != WindowPlacement.Fullscreen) {
                                        if (state.placement == WindowPlacement.Maximized) {
                                            state.placement = WindowPlacement.Floating
                                        } else {
                                            state.placement = WindowPlacement.Maximized
                                        }
                                    }
                                },
                            ),
                            title = {
                                Text("Yaba")
                            },
                            navigationIcon = {
                                Row(
                                    modifier = Modifier.padding(start = 12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .onPointerEvent(PointerEventType.Enter) {
                                                isMauseEnteredToSystemButtons = true
                                            }
                                            .onPointerEvent(PointerEventType.Exit) {
                                                isMauseEnteredToSystemButtons = false
                                            },
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    ) {
                                        YabaNixSystemButton(
                                            type = YabaSystemButtonType.CLOSE,
                                            isHovered = isMauseEnteredToSystemButtons,
                                            isFullScreen = state.placement == WindowPlacement.Fullscreen,
                                            onClick = ::exitApplication
                                        )
                                        YabaNixSystemButton(
                                            type = YabaSystemButtonType.MINIMZE,
                                            isHovered = isMauseEnteredToSystemButtons,
                                            isFullScreen = state.placement == WindowPlacement.Fullscreen,
                                            onClick = {
                                                if (state.placement != WindowPlacement.Fullscreen) {
                                                    state.isMinimized = true
                                                }
                                            }
                                        )
                                        YabaNixSystemButton(
                                            type = YabaSystemButtonType.FULLSCREEN,
                                            isHovered = isMauseEnteredToSystemButtons,
                                            isFullScreen = state.placement == WindowPlacement.Fullscreen,
                                            onClick = {
                                                if (state.placement == WindowPlacement.Fullscreen) {
                                                    state.placement = WindowPlacement.Floating
                                                } else {
                                                    state.placement = WindowPlacement.Fullscreen
                                                }
                                            }
                                        )
                                    }
                                    YabaIconButton(
                                        onClick = {

                                        }
                                    ) {
                                        Image(
                                            painter = painterResource(Res.drawable.ic_left_panel),
                                            contentDescription = "Open Left Panel",
                                        )
                                    }
                                }
                            },
                            actions = {
                                Row(
                                    modifier = Modifier.padding(end = 12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(0.dp),
                                ) {
                                    YabaDosSystemButton(
                                        type = YabaSystemButtonType.MINIMZE,
                                        isFullScreen = state.placement == WindowPlacement.Fullscreen,
                                        onClick = {
                                            if (state.placement != WindowPlacement.Fullscreen) {
                                                state.isMinimized = true
                                            }
                                        }
                                    )
                                    YabaDosSystemButton(
                                        type = YabaSystemButtonType.FULLSCREEN,
                                        isFullScreen = state.placement == WindowPlacement.Fullscreen,
                                        onClick = {
                                            if (state.placement == WindowPlacement.Fullscreen) {
                                                state.placement = WindowPlacement.Floating
                                            } else {
                                                state.placement = WindowPlacement.Fullscreen
                                            }
                                        }
                                    )
                                    YabaDosSystemButton(
                                        type = YabaSystemButtonType.CLOSE,
                                        isFullScreen = state.placement == WindowPlacement.Fullscreen,
                                        onClick = ::exitApplication
                                    )
                                }
                            }
                        )
                    },
                    floatingActionButton = {
                        YabaFab(
                            onClick = {

                            }
                        ) {
                            Icon(
                                modifier = Modifier.padding(end = 16.dp),
                                imageVector = Icons.TwoTone.BookmarkAdd,
                                contentDescription = "Create new Bookmark",
                            )
                            Text("Kaydet")
                        }
                    },
                ) {
                    LazyVerticalGrid(
                        modifier = Modifier.padding(it),
                        columns = GridCells.Adaptive(minSize = 300.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        contentPadding = PaddingValues(16.dp),
                    ) {
                        items(100000) {
                            YabaCard(
                                modifier = Modifier.size(300.dp),
                                onClick = {},
                            ) {
                                Box(
                                    modifier = Modifier.fillMaxSize(),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Text(
                                        text = "Berat SeLAM",
                                        style = MaterialTheme.typography.bodyLarge,
                                    )
                                }
                            }
                        }
                    }
                }
            }

        }

         */
    }
}