package core.components.layout

import Platform
import androidx.compose.foundation.layout.RowScope
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import core.theme.ThemeStateProvider
import currentPlatform

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun YabaAppBar(
    title: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    navigationIcon: @Composable () -> Unit = {},
    actions: @Composable RowScope.() -> Unit = {},
    scrollBehavior: TopAppBarScrollBehavior? = null
) {
    val themeState = ThemeStateProvider.current

    if (currentPlatform == Platform.DESKTOP) {
        TopAppBar(
            modifier = modifier,
            title = title,
            navigationIcon = navigationIcon,
            actions = actions,
            scrollBehavior = scrollBehavior,
            colors = TopAppBarDefaults.topAppBarColors().copy(
                containerColor = Color.Transparent,
                scrolledContainerColor = Color.Transparent,
                titleContentColor = themeState.colors.onBackground,
                navigationIconContentColor = themeState.colors.onBackground,
                actionIconContentColor = themeState.colors.onBackground,
            ),
        )
    } else {
        LargeTopAppBar(
            modifier = modifier,
            title = title,
            navigationIcon = navigationIcon,
            actions = actions,
            scrollBehavior = scrollBehavior,
            colors = TopAppBarDefaults.topAppBarColors().copy(
                containerColor = Color.Transparent,
                scrolledContainerColor = Color.Transparent,
                titleContentColor = themeState.colors.onBackground,
                navigationIconContentColor = themeState.colors.onBackground,
                actionIconContentColor = themeState.colors.onBackground,
            ),
        )
    }
}
