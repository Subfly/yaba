package di.modules

import org.koin.androidx.viewmodel.dsl.viewModel
import org.koin.core.module.Module
import org.koin.dsl.module
import state.creation.CreateOrEditContentStateMachine
import state.content.ContentProvider
import state.detail.FolderDetailState
import state.detail.FolderDetailStateMachine

actual val viewModelsModule: Module = module {
    viewModel<ContentProvider> { ContentProvider() }
    viewModel<CreateOrEditContentStateMachine> { CreateOrEditContentStateMachine() }
    viewModel<FolderDetailStateMachine> { FolderDetailStateMachine() }
}
