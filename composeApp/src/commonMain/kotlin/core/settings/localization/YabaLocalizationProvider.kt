package core.settings.localization

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf
import core.settings.localization.assets.YabaLocalizationState

val LocalizationStateProvider: ProvidableCompositionLocal<YabaLocalizationState> =
    staticCompositionLocalOf {
        YabaLocalizationState()
    }

val LocalizationManagerProvider: ProvidableCompositionLocal<YabaLocalizationManager?> =
    staticCompositionLocalOf {
        null
    }