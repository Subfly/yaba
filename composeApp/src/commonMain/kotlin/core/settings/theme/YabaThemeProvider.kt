package core.settings.theme

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf

val ThemeStateProvider: ProvidableCompositionLocal<YabaThemeState> =
    staticCompositionLocalOf {
        YabaThemeState()
    }

val ThemeManagerProvider: ProvidableCompositionLocal<YabaThemeManager?> =
    staticCompositionLocalOf {
        null
    }