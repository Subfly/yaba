package core.localization.assets

import core.localization.assets.accessibility.EnglishAccessibility
import core.localization.assets.accessibility.YabaAccessibility
import core.localization.assets.localization.EnglishLocalization
import core.localization.assets.localization.YabaLocalization
import core.util.selections.LanguageSelection

data class YabaLocalizationState(
    val currentLocal: LanguageSelection = LanguageSelection.EN,
    val localization: YabaLocalization = EnglishLocalization(),
    val accessibility: YabaAccessibility = EnglishAccessibility(),
)
