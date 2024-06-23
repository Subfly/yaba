package navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import core.util.extensions.koinViewModel
import state.home.HomeStateMachine
import view.mobile.home.HomeScreen
import view.mobile.search.SearchScreen
import view.mobile.settings.SettingsScreen

@Composable
fun YabaMobileNavigation(
    modifier: Modifier = Modifier,
    navHostController: NavHostController,
) {
    NavHost(
        modifier = modifier,
        navController = navHostController,
        startDestination = YabaScreens.HOME.route,
    ) {
        composable(
            route = YabaScreens.HOME.route,
        ) {
            val viewModel = koinViewModel<HomeStateMachine>()
            val state by viewModel.state.collectAsState()

            HomeScreen(
                state = state,
                onClickSearch = {
                    navHostController.navigate(YabaScreens.SEARCH.route)
                },
                onClickSync = {
                    navHostController.navigate(YabaScreens.SYNC.route)
                },
                onClickSettings = {
                    navHostController.navigate(YabaScreens.SETTINGS.route)
                },
            )
        }
        composable(
            route = YabaScreens.SEARCH.route,
        ) {
            SearchScreen(
                onClickBack = {
                    navHostController.popBackStack()
                }
            )
        }
        composable(
            route = YabaScreens.SETTINGS.route,
        ) {
            SettingsScreen(
                onClickBack = {
                    navHostController.popBackStack()
                }
            )
        }
    }
}
