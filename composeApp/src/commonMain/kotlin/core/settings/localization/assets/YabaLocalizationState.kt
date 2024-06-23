package core.settings.localization.assets

import core.settings.localization.assets.accessibility.EnglishAccessibility
import core.settings.localization.assets.accessibility.YabaAccessibility
import core.settings.localization.assets.localization.EnglishLocalization
import core.settings.localization.assets.localization.YabaLocalization
import core.util.selections.LanguageSelection

data class YabaLocalizationState(
    val currentLocal: LanguageSelection = LanguageSelection.EN,
    val localization: YabaLocalization = EnglishLocalization(),
    val accessibility: YabaAccessibility = EnglishAccessibility(),
)
