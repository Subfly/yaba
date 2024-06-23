package state.base

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.SupervisorJob
import org.koin.core.component.KoinComponent

abstract class BaseStateMachine<E>(
    private val coroutineScope: CoroutineScope? = null,
) : KoinComponent {
    // Scope Definition
    val stateMachineScope = coroutineScope ?: CoroutineScope(Dispatchers.IO)
    val mainDispatcher = Dispatchers.Main + SupervisorJob()

    // Event Handler
    abstract fun onEvent(event: E)

    // Dispose
    abstract fun dispose()
}
