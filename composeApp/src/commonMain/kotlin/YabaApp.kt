import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.compose.rememberNavController
import core.settings.contentview.ContentViewStyleManagerProvider
import core.settings.contentview.ContentViewStyleStateProvider
import core.settings.contentview.YabaContentViewStyleManager
import core.settings.localization.LocalizationManagerProvider
import core.settings.localization.LocalizationStateProvider
import core.settings.localization.YabaLocalizationManager
import core.settings.theme.ThemeManagerProvider
import core.settings.theme.ThemeStateProvider
import core.settings.theme.YabaThemeManager
import core.settings.theme.components.YabaTheme
import core.util.extensions.koinViewModel
import core.util.selections.ThemeSelection
import navigation.YabaMobileNavigation
import org.jetbrains.compose.ui.tooling.preview.Preview
import org.koin.compose.KoinContext
import state.content.ContentProvider
import state.content.ContentStateProvider
import state.creation.CreateOrEditContentStateMachine
import state.creation.CreateOrEditContentStateMachineProvider
import state.manager.DatasourceCRUDManager
import state.manager.DatasourceCRUDManagerProvider
import view.mobile.creation.CreateOrEditContentSheet

@Composable
@Preview
fun YabaApp() {
    val isSystemInDarkTheme = isSystemInDarkTheme()
    val themeManager = koinViewModel<YabaThemeManager>()
    val localizationManager = koinViewModel<YabaLocalizationManager>()
    val contentViewStyleManager = koinViewModel<YabaContentViewStyleManager>()
    val createOrEditContentStateMachine = koinViewModel<CreateOrEditContentStateMachine>()
    val datasourceCRUDManager = koinViewModel<DatasourceCRUDManager>()

    val contentProvider = koinViewModel<ContentProvider>()

    val themeState by themeManager.state.collectAsState()
    val localizationState by localizationManager.state.collectAsState()
    val contentViewStyleState by contentViewStyleManager.state.collectAsState()
    val contentState by contentProvider.state.collectAsState()

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
            ContentViewStyleStateProvider provides contentViewStyleState,
            ContentViewStyleManagerProvider provides contentViewStyleManager,
            CreateOrEditContentStateMachineProvider provides createOrEditContentStateMachine,
            DatasourceCRUDManagerProvider provides datasourceCRUDManager,
            ContentStateProvider provides contentState,
        ) {
            YabaTheme {
                Box(modifier = Modifier.fillMaxSize()) {
                    YabaMobileNavigation(
                        modifier = Modifier,
                        navHostController = rememberNavController()
                    )
                    CreateOrEditContentSheet()
                }
            }
        }
    }
}
