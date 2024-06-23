package di

import di.modules.controllersModule
import di.modules.dataModule
import di.modules.databaseBuilderFactoryModule
import di.modules.datastorePreferencesModule
import di.modules.managersModule
import di.modules.viewModelsModule
import org.koin.core.context.startKoin
import org.koin.dsl.KoinAppDeclaration

object DIHelper {
    fun initKoin(
        appDeclaration: KoinAppDeclaration = {}
    ) = startKoin {
        appDeclaration()
        modules(
            databaseBuilderFactoryModule
                    + dataModule
                    + datastorePreferencesModule
                    + controllersModule
                    + managersModule
                    + viewModelsModule
        )
    }

    // For iOS
    fun initKoin() = initKoin {}
}
