package core.settings.contentview

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf

val ContentViewStyleStateProvider: ProvidableCompositionLocal<YabaContentViewStyleState> =
    staticCompositionLocalOf {
        YabaContentViewStyleState()
    }

val ContentViewStyleManagerProvider: ProvidableCompositionLocal<YabaContentViewStyleManager?> =
    staticCompositionLocalOf {
        null
    }