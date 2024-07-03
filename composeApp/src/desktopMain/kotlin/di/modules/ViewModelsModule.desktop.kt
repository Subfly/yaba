package di.modules

import org.koin.core.module.Module
import org.koin.dsl.module
import state.creation.CreateOrEditContentStateMachine
import state.content.ContentProvider
import state.detail.folder.FolderDetailStateMachine
import state.detail.tag.TagDetailStateMachine

actual val viewModelsModule: Module = module {
    single<ContentProvider> { ContentProvider() }
    single<CreateOrEditContentStateMachine> { CreateOrEditContentStateMachine() }
    factory<FolderDetailStateMachine> { FolderDetailStateMachine() }
    factory<TagDetailStateMachine> { TagDetailStateMachine() }
}
