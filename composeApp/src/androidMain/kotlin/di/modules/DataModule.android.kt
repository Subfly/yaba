package di.modules

import android.content.Context
import androidx.room.RoomDatabase
import data.YabaDatabase
import data.getDatabaseBuilder
import org.koin.core.module.Module
import org.koin.dsl.module

actual val databaseBuilderFactoryModule: Module = module {
    single<RoomDatabase.Builder<YabaDatabase>> {
        getDatabaseBuilder(context = get<Context>())
    }
}
