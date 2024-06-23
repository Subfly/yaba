package core.settings.contentview

import core.util.selections.ContentViewSelection

data class YabaContentViewStyleState(
    val currentStyle: ContentViewSelection = ContentViewSelection.GRID,
)
