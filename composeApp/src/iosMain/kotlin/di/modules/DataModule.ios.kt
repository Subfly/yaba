package di.modules

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import co.touchlab.sqliter.DatabaseConfiguration
import core.constants.DatabaseConstants
import dev.subfly.YabaDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

actual val databaseBuilderFactoryModule: Module = module {
    single<SqlDriver> {
        NativeSqliteDriver(
            schema = YabaDatabase.Schema,
            name = DatabaseConstants.DATABASE_NAME,
            onConfiguration = { config: DatabaseConfiguration ->
                config.copy(
                    extendedConfig = DatabaseConfiguration.Extended(
                        foreignKeyConstraints = true,
                    )
                )
            }
        )
    }
}
