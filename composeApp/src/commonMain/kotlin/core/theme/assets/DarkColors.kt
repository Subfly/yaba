package core.theme.assets

import androidx.compose.ui.graphics.Color

class DarkColors : YabaColors() {
    override val primary: Color
        get() = Color(0xFF3675B8)
    override val onPrimary: Color
        get() = Color(0xFFF7F7F7)
    override val secondary: Color
        get() = Color(0xFFF55D3E)
    override val onSecondary: Color
        get() = Color(0xFFF7F7F7)
    override val background: Color
        get() = Color(0xFF161616)
    override val onBackground: Color
        get() = Color(0xFFF7F7F7)
    override val surface: Color
        get() = Color(0xFF21222B)
    override val onSurface: Color
        get() = Color(0xFFF7F7F7)
    override val error: Color
        get() = Color(0xFFAB3224)
    override val onError: Color
        get() = Color(0xFFF7F7F7)
}