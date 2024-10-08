package core.util.selections

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.FormatListNumbered
import androidx.compose.material.icons.twotone.SpaceDashboard
import androidx.compose.ui.graphics.vector.ImageVector
import core.settings.localization.assets.accessibility.YabaAccessibility
import core.settings.localization.assets.localization.YabaLocalization

enum class ContentViewSelection(
    val key: String,
    val icon: ImageVector,
) {
    GRID(
        key = "grid",
        icon = Icons.TwoTone.SpaceDashboard,
    ),
    LIST(
        key = "list",
        icon = Icons.TwoTone.FormatListNumbered,
    );

    fun getDescription(accessibility: YabaAccessibility): String {
        return when (this) {
            GRID -> accessibility.GRID_VIEW_ICON_DESCRIPTION
            LIST -> accessibility.LIST_VIEW_ICON_DESCRIPTION
        }
    }

    fun getUIText(localization: YabaLocalization): String {
        return when (this) {
            GRID -> localization.CONTENT_VIEW_SELECTION_GRID
            LIST -> localization.CONTENT_VIEW_SELECTION_LIST
        }
    }
}