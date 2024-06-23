package core.settings.theme

import core.settings.theme.assets.DarkColors
import core.settings.theme.assets.YabaColors
import core.util.selections.ThemeSelection

data class YabaThemeState(
    val currentSelectedTheme: ThemeSelection = ThemeSelection.SYSTEM,
    val colors: YabaColors = DarkColors()
)
