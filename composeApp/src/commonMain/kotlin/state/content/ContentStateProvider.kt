package state.content

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf

val ContentStateProvider: ProvidableCompositionLocal<ContentState> =
    staticCompositionLocalOf {
        ContentState()
    }