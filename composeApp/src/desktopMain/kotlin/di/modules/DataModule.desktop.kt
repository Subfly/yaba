package di.modules

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver
import dev.subfly.YabaDatabase
import org.koin.core.module.Module
import org.koin.dsl.module
import java.util.Properties

actual val databaseBuilderFactoryModule: Module = module {
    // TODO: UPDATE HERE FOR PERSISTENCE
    single<SqlDriver> {
        val driver = JdbcSqliteDriver(
            url = JdbcSqliteDriver.IN_MEMORY,
            properties = Properties().apply { put("foreign_keys", "true") },
        )
        YabaDatabase.Schema.create(driver = driver)

        /* return */ driver
    }
}
