package di.modules

import app.cash.sqldelight.db.SqlDriver
import data.YabaDatasource
import dev.subfly.YabaDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

expect val databaseBuilderFactoryModule: Module

val dataModule: Module = module {
    single<YabaDatabase> {
        YabaDatabase(get<SqlDriver>())
    }
    single<YabaDatasource> {
        YabaDatasource(get<YabaDatabase>())
    }
}
