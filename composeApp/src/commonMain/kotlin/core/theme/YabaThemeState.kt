package core.theme

import core.theme.assets.DarkColors
import core.theme.assets.YabaColors
import core.util.selections.ThemeSelection

data class YabaThemeState(
    val currentSelectedTheme: ThemeSelection = ThemeSelection.SYSTEM,
    val colors: YabaColors = DarkColors()
)
