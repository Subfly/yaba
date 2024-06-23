package state.manager

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf

val DatasourceCUDManagerProvider: ProvidableCompositionLocal<DatasourceCUDManager?> =
    staticCompositionLocalOf {
        null
    }