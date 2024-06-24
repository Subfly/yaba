package state.manager

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf

val DatasourceCRUDManagerProvider: ProvidableCompositionLocal<DatasourceCRUDManager?> =
    staticCompositionLocalOf {
        null
    }