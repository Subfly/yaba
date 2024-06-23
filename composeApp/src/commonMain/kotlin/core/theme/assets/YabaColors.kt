package core.theme.assets

import androidx.compose.ui.graphics.Color

abstract class YabaColors {
    abstract val primary: Color
    abstract val onPrimary: Color
    abstract val secondary: Color
    abstract val onSecondary: Color
    abstract val background: Color
    abstract val onBackground: Color
    abstract val surface: Color
    abstract val onSurface: Color
    abstract val error: Color
    abstract val onError: Color

    val creamyWhite: Color
        get() = Color(0xFFF7F7F7)

    val systemCloseColor: Color
        get() = Color(0xFFFF605C)
    val systemMinimizeColor: Color
        get() = Color(0xFFFFBD44)
    val systemFullscreenColor: Color
        get() = Color(0xFF00CA4E)
    val systemDisabledColor: Color
        get() = Color(0xFFA9A9A9)
}
