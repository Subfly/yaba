package di.modules

import core.settings.contentview.YabaContentViewStyleController
import core.settings.contentview.YabaContentViewStyleManager
import core.settings.localization.YabaLocalizationController
import core.settings.localization.YabaLocalizationManager
import core.settings.theme.YabaThemeController
import core.settings.theme.YabaThemeManager
import data.YabaDatasource
import org.koin.core.module.Module
import org.koin.dsl.module
import state.manager.DatasourceCUDManager

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
    single<DatasourceCUDManager> {
        DatasourceCUDManager(datasource = get<YabaDatasource>())
    }
}
