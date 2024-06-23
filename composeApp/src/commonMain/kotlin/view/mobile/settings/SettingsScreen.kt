package view.mobile.settings

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import core.components.layout.YabaScaffold
import core.constants.GeneralConstants
import core.settings.contentview.ContentViewStyleManagerProvider
import core.settings.localization.LocalizationManagerProvider
import core.settings.theme.ThemeManagerProvider
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import view.mobile.settings.components.SettingsAppBar
import view.mobile.settings.components.SettingsContentSettingsComponent
import view.mobile.settings.components.SettingsThemeAndLanguageSelectionComponent
import view.mobile.settings.components.sheet.SettingsOptionsSheet
import view.mobile.settings.components.sheet.SettingsSheetType

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
) {
    val isSystemInDarkTheme = isSystemInDarkTheme()

    val themeManager = ThemeManagerProvider.current
    val localizationManager = LocalizationManagerProvider.current
    val contentViewStyleManager = ContentViewStyleManagerProvider.current

    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    val scope = rememberCoroutineScope()
    val optionsSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    var shouldShowOptionsSheet by remember { mutableStateOf(false) }
    var currentSheetType by remember { mutableStateOf(SettingsSheetType.NONE) }

    YabaScaffold(
        modifier = modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            SettingsAppBar(
                scrollBehavior = scrollBehavior,
                onClickBack = onClickBack,
            )
        }
    ) { paddings ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddings)
        ) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                item {
                    SettingsThemeAndLanguageSelectionComponent(
                        onClickChangeTheme = {
                            scope.launch {
                                currentSheetType = SettingsSheetType.THEME
                                delay(GeneralConstants.MAGIC_THREE_FRAME_SKIP_DURATION)
                                shouldShowOptionsSheet = true
                            }
                        },
                        onClickChangeLanguage = {
                            scope.launch {
                                currentSheetType = SettingsSheetType.LANGUAGE
                                delay(GeneralConstants.MAGIC_THREE_FRAME_SKIP_DURATION)
                                shouldShowOptionsSheet = true
                            }
                        }
                    )
                }
                item {
                    SettingsContentSettingsComponent(
                        onClickChangeContentViewStyle = {
                            scope.launch {
                                currentSheetType = SettingsSheetType.CONTENT_VIEW_STYLE
                                delay(GeneralConstants.MAGIC_THREE_FRAME_SKIP_DURATION)
                                shouldShowOptionsSheet = true
                            }
                        }
                    )
                }
            }

            if (shouldShowOptionsSheet) {
                SettingsOptionsSheet(
                    type = currentSheetType,
                    sheetState = optionsSheetState,
                    onDismissRequest = {
                        scope.launch {
                            shouldShowOptionsSheet = false
                            delay(150)
                            currentSheetType = SettingsSheetType.NONE
                        }
                    },
                    onClickLanguage = {
                        scope.launch {
                            localizationManager?.onNewLanguageSelected(it)
                            shouldShowOptionsSheet = false
                            delay(150)
                            currentSheetType = SettingsSheetType.NONE
                        }
                    },
                    onClickTheme = {
                        scope.launch {
                            themeManager?.onThemeChanged(
                                newThemeSelection = it,
                                isSystemInDark = isSystemInDarkTheme,
                            )
                            shouldShowOptionsSheet = false
                            delay(150)
                            currentSheetType = SettingsSheetType.NONE
                        }
                    },
                    onClickStyle = {
                        scope.launch {
                            contentViewStyleManager?.onNewStyleSelected(newStyle = it)
                            shouldShowOptionsSheet = false
                            delay(150)
                            currentSheetType = SettingsSheetType.NONE
                        }
                    }
                )
            }
        }
    }
}
