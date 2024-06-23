package core.localization

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf
import core.localization.assets.YabaLocalizationState

val LocalizationStateProvider: ProvidableCompositionLocal<YabaLocalizationState> =
    staticCompositionLocalOf {
        YabaLocalizationState()
    }

val LocalizationManagerProvider: ProvidableCompositionLocal<YabaLocalizationManager?> =
    staticCompositionLocalOf {
        null
    }