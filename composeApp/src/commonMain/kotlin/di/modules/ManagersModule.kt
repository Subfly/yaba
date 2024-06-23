package di.modules

import core.settings.contentview.YabaContentViewStyleController
import core.settings.contentview.YabaContentViewStyleManager
import core.settings.localization.YabaLocalizationController
import core.settings.localization.YabaLocalizationManager
import core.settings.theme.YabaThemeController
import core.settings.theme.YabaThemeManager
import org.koin.core.module.Module
import org.koin.dsl.module

val managersModule: Module = module {
    single<YabaThemeManager> {
        YabaThemeManager(controller = get<YabaThemeController>())
    }
    single<YabaLocalizationManager> {
        YabaLocalizationManager(controller = get<YabaLocalizationController>())
    }
    single<YabaContentViewStyleManager> {
        YabaContentViewStyleManager(controller = get<YabaContentViewStyleController>())
    }
}
