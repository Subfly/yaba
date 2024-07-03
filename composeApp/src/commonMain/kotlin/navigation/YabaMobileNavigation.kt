package navigation

import Platform
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.material.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import core.settings.theme.ThemeStateProvider
import core.util.extensions.koinViewModel
import currentPlatform
import state.content.ContentProvider
import view.mobile.detail.folder.FolderDetail
import view.mobile.detail.tag.TagDetail
import view.mobile.home.HomeScreen
import view.mobile.search.SearchScreen
import view.mobile.settings.SettingsScreen

@Composable
fun YabaMobileNavigation(
    modifier: Modifier = Modifier,
    navHostController: NavHostController,
) {
    val themeState = ThemeStateProvider.current

    Surface(
        color = themeState.colors.surface,
    ) {
        NavHost(
            modifier = modifier,
            navController = navHostController,
            startDestination = YabaScreens.HOME.route,
            enterTransition = {
                if (currentPlatform == Platform.IOS) {
                    slideIntoContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Left
                    )
                } else {
                    fadeIn(animationSpec = tween(700))
                }
            },
            exitTransition = {
                if (currentPlatform == Platform.IOS) {
                    slideOutOfContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Right
                    )
                } else {
                    fadeOut(animationSpec = tween(700))
                }
            }
        ) {
            composable(
                route = YabaScreens.HOME.route,
            ) {
                HomeScreen(
                    onClickSearch = {
                        navHostController.navigate(YabaScreens.SEARCH.route)
                    },
                    onClickSync = {
                        navHostController.navigate(YabaScreens.SYNC.route)
                    },
                    onClickSettings = {
                        navHostController.navigate(YabaScreens.SETTINGS.route)
                    },
                    onClickFolder = { folderId, folderName ->
                        navHostController.navigate(
                            YabaScreens.FOLDER_DETAIL.route + "/$folderName/$folderId",
                        )
                    },
                    onClickTag = { tagId, tagName ->
                        navHostController.navigate(
                            YabaScreens.TAG_DETAIL.route + "/$tagName/$tagId",
                        )
                    }
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
            composable(
                route = YabaScreens.FOLDER_DETAIL.route + "/{folderName}/{folderId}",
                arguments = listOf(
                    navArgument(name = "folderName") { type = NavType.StringType },
                    navArgument(name = "folderId") { type = NavType.LongType },
                )
            ) { navBackStackEntry ->
                val folderName = navBackStackEntry.arguments?.getString("folderName").orEmpty()
                val folderId = navBackStackEntry.arguments?.getLong("folderId") ?: -1
                FolderDetail(
                    folderId = folderId,
                    folderName = folderName,
                    onClickBack = {
                        navHostController.popBackStack()
                    }
                )
            }
            composable(
                route = YabaScreens.TAG_DETAIL.route + "/{tagName}/{tagId}",
                arguments = listOf(
                    navArgument(name = "tagName") { type = NavType.StringType },
                    navArgument(name = "tagId") { type = NavType.LongType },
                )
            ) { navBackStackEntry ->
                val folderName = navBackStackEntry.arguments?.getString("tagName").orEmpty()
                val folderId = navBackStackEntry.arguments?.getLong("tagId") ?: -1
                TagDetail(
                    tagId = folderId,
                    tagName = folderName,
                    onClickBack = {
                        navHostController.popBackStack()
                    }
                )
            }
        }
    }
}
