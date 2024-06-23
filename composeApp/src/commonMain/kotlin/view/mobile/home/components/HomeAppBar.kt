package view.mobile.home.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import core.components.layout.YabaAppBar
import core.components.button.YabaIconButton
import core.components.layout.YabaMenu
import core.components.layout.YabaMenuItem
import core.localization.LocalizationStateProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun HomeAppBar(
    scrollBehavior: TopAppBarScrollBehavior? = null,
    onClickSearch: () -> Unit,
    onClickSync: () -> Unit,
    onClickSettings: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current
    var isMenuExpanded by remember { mutableStateOf(false) }

    YabaAppBar(
        scrollBehavior = scrollBehavior,
        title = {
            Text(localizationProvider.localization.APP_NAME)
        },
        actions = {
            YabaIconButton(onClick = onClickSearch) {
                Icon(
                    imageVector = Icons.TwoTone.Search,
                    contentDescription = localizationProvider.accessibility.SEARCH_ICON_DESCIPTION
                )
            }
            YabaIconButton(
                onClick = { isMenuExpanded = true },
            ) {
                Icon(
                    imageVector = Icons.TwoTone.MoreVert,
                    contentDescription = localizationProvider.accessibility.SHOW_MORE_ICON_DESCRIPTION
                )
            }
            YabaMenu(
                expanded = isMenuExpanded,
                onDismissRequest = {
                    isMenuExpanded = false
                },
            ) {
                YabaMenuItem(
                    text = {
                        Text(localizationProvider.localization.SYNC)
                    },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.TwoTone.Phonelink,
                            contentDescription = localizationProvider.accessibility.SYNC_ICON_DESCRIPTION,
                        )
                    },
                    onClick = {
                        isMenuExpanded = false
                        onClickSync.invoke()
                    },
                )
                YabaMenuItem(
                    text = {
                        Text(localizationProvider.localization.SETTINGS)
                    },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.TwoTone.Settings,
                            contentDescription = localizationProvider.accessibility.SETTINGS_ICON_DESCRIPTION,
                        )
                    },
                    onClick = {
                        isMenuExpanded = false
                        onClickSettings.invoke()
                    },
                )
            }
        },
    )
}
