package core.theme.assets

import androidx.compose.ui.graphics.Color

class LightColors : YabaColors() {
    override val primary: Color
        get() = Color(0xFF367588)
    override val onPrimary: Color
        get() = Color(0xFF21221B)
    override val secondary: Color
        get() = Color(0xFFF97639)
    override val onSecondary: Color
        get() = Color(0xFFF7F7F7)
    override val background: Color
        get() = Color(0xFFFAF9F6)
    override val onBackground: Color
        get() = Color(0xFF21221B)
    override val surface: Color
        get() = Color(0xFFF1F1F1)
    override val onSurface: Color
        get() = Color(0xFF21221B)
    override val error: Color
        get() = Color(0xFFAB3224)
    override val onError: Color
        get() = Color(0xFF21221B)
}
