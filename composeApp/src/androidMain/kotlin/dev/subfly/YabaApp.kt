package dev.subfly

import android.app.Application
import di.DIHelper
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.logger.Level

class YabaApp : Application() {
    override fun onCreate() {
        DIHelper.initKoin {
            androidLogger(level = Level.ERROR)
            androidContext(androidContext = this@YabaApp)
        }
        super.onCreate()
    }
}