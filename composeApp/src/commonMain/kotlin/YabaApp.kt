import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.compose.rememberNavController
import core.localization.LocalizationManagerProvider
import core.localization.LocalizationStateProvider
import core.localization.YabaLocalizationManager
import core.theme.ThemeManagerProvider
import core.theme.ThemeStateProvider
import core.theme.YabaThemeManager
import core.theme.components.YabaTheme
import core.util.selections.ThemeSelection
import navigation.YabaMobileNavigation
import org.jetbrains.compose.ui.tooling.preview.Preview
import org.koin.compose.KoinContext
import org.koin.compose.koinInject

@Composable
@Preview
fun YabaApp() {
    val isSystemInDarkTheme = isSystemInDarkTheme()
    val themeManager = koinInject<YabaThemeManager>()
    val localizationManager = koinInject<YabaLocalizationManager>()

    val themeState by themeManager.state.collectAsState()
    val localizationState by localizationManager.state.collectAsState()

    LaunchedEffect(isSystemInDarkTheme) {
        if (themeState.currentSelectedTheme == ThemeSelection.SYSTEM) {
            themeManager.onThemeChanged(
                newThemeSelection = themeState.currentSelectedTheme,
                isSystemInDark = isSystemInDarkTheme,
            )
        }
    }

    LaunchedEffect(Unit) {
        themeManager.fetchTheme(isSystemInDark = isSystemInDarkTheme)
    }

    KoinContext {
        CompositionLocalProvider(
            ThemeStateProvider provides themeState,
            ThemeManagerProvider provides themeManager,
            LocalizationStateProvider provides localizationState,
            LocalizationManagerProvider provides localizationManager,
        ) {
            YabaTheme {
                YabaMobileNavigation(
                    modifier = Modifier,
                    navHostController = rememberNavController()
                )
            }
        }
    }
}
