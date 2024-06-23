package state.creation

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf

val CreateOrEditContentStateMachineProvider: ProvidableCompositionLocal<CreateOrEditContentStateMachine?> =
    staticCompositionLocalOf {
        null
    }