package core.util.selections

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.FormatListNumbered
import androidx.compose.material.icons.twotone.SpaceDashboard
import androidx.compose.ui.graphics.vector.ImageVector
import core.settings.localization.assets.accessibility.YabaAccessibility

enum class ContentViewSelection(val icon: ImageVector) {
    GRID(
        icon = Icons.TwoTone.SpaceDashboard,
    ),
    LIST(
        icon = Icons.TwoTone.FormatListNumbered,
    );

    fun getDescription(accessibility: YabaAccessibility): String {
        return when(this) {
            GRID -> accessibility.GRID_VIEW_ICON_DESCRIPTION
            LIST -> accessibility.LIST_VIEW_ICON_DESCRIPTION
        }
    }
}