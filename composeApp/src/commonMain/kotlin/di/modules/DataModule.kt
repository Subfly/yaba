package di.modules

import androidx.room.RoomDatabase
import data.YabaDatabase
import data.createYabaDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

expect val databaseBuilderFactoryModule: Module

val dataModule: Module = module {
    single<YabaDatabase> {
        createYabaDatabase(
            builder = get<RoomDatabase.Builder<YabaDatabase>>(),
        )
    }
}
