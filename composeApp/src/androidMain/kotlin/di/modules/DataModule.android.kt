package di.modules

import android.content.Context
import androidx.sqlite.db.SupportSQLiteDatabase
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import core.constants.DatabaseConstants
import dev.subfly.YabaDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

actual val databaseBuilderFactoryModule: Module = module {
    single<SqlDriver> {
        AndroidSqliteDriver(
            schema = YabaDatabase.Schema,
            context = get<Context>(),
            name = DatabaseConstants.DATABASE_NAME,
            callback = object : AndroidSqliteDriver.Callback(YabaDatabase.Schema) {
                override fun onOpen(db: SupportSQLiteDatabase) {
                    db.setForeignKeyConstraintsEnabled(true)
                }
            }
        )
    }
}
