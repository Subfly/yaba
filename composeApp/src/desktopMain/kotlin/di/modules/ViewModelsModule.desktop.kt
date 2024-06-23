package di.modules

import org.koin.core.module.Module
import org.koin.dsl.module
import state.creation.CreateOrEditContentStateMachine
import state.home.HomeStateMachine

actual val viewModelsModule: Module = module {
    single<HomeStateMachine> { HomeStateMachine() }
    single<CreateOrEditContentStateMachine> { CreateOrEditContentStateMachine() }
}
