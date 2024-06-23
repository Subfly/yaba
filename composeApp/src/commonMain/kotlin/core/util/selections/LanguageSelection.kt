package core.util.selections

import core.localization.assets.localization.YabaLocalization

enum class LanguageSelection(val key: String) {
    TR("tr"),
    EN("en");

    fun getUIText(localization: YabaLocalization): String {
        return when(this) {
            TR -> localization.LANGUAGE_SELECTION_TR
            EN -> localization.LANGUAGE_SELECTION_EN
        }
    }
}
