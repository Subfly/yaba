package core.util.selections

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.DarkMode
import androidx.compose.material.icons.twotone.LightMode
import androidx.compose.material.icons.twotone.Settings
import androidx.compose.ui.graphics.vector.ImageVector
import core.localization.assets.accessibility.YabaAccessibility
import core.localization.assets.localization.YabaLocalization

enum class ThemeSelection(val key: String) {
    SYSTEM("system"),
    DARK("dark"),
    LIGHT("light");

    fun getUIIcon(): ImageVector {
        return when (this) {
            SYSTEM -> Icons.TwoTone.Settings
            DARK -> Icons.TwoTone.DarkMode
            LIGHT -> Icons.TwoTone.LightMode
        }
    }

    fun getDescription(accessibility: YabaAccessibility): String {
        return when (this) {
            SYSTEM -> accessibility.SETTINGS_SYSTEM_THEME_ICON_DESCRIPTION
            DARK -> accessibility.SETTINGS_DARK_THEME_ICON_DESCRIPTION
            LIGHT -> accessibility.SETTINGS_LIGHT_THEME_ICON_DESCRIPTION
        }
    }

    fun getUIText(localization: YabaLocalization): String {
        return when (this) {
            SYSTEM -> localization.THEME_SELECTION_OPTION_SYSTEM
            DARK -> localization.THEME_SELECTION_OPTION_DARK
            LIGHT -> localization.THEME_SELECTION_OPTION_LIGHT
        }
    }
}
