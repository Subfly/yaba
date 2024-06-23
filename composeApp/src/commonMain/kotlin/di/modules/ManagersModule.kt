package di.modules

import core.localization.YabaLocalizationController
import core.localization.YabaLocalizationManager
import core.theme.YabaThemeController
import core.theme.YabaThemeManager
import org.koin.core.module.Module
import org.koin.dsl.module

val managersModule: Module = module {
    single<YabaThemeManager> {
        YabaThemeManager(controller = get<YabaThemeController>())
    }
    single<YabaLocalizationManager> {
        YabaLocalizationManager(controller = get<YabaLocalizationController>())
    }
}
