package core.settings.theme.assets

import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import org.jetbrains.compose.resources.Font
import yaba.composeapp.generated.resources.*
import yaba.composeapp.generated.resources.Quicksand_Light
import yaba.composeapp.generated.resources.Quicksand_Medium
import yaba.composeapp.generated.resources.Quicksand_Regular
import yaba.composeapp.generated.resources.Res

object YabaTypography {
    @Composable
    internal fun QuicksandFontFamily() = FontFamily(
        Font(Res.font.Quicksand_Light, weight = FontWeight.Light),
        Font(Res.font.Quicksand_Regular, weight = FontWeight.Normal),
        Font(Res.font.Quicksand_Medium, weight = FontWeight.Medium),
        Font(Res.font.Quicksand_SemiBold, weight = FontWeight.SemiBold),
        Font(Res.font.Quicksand_Bold, weight = FontWeight.Bold)
    )

    @Composable
    fun getTypography() = Typography().run {
        val fontFamily = QuicksandFontFamily()
        copy(
            displayLarge = displayLarge.copy(fontFamily = fontFamily),
            displayMedium = displayMedium.copy(fontFamily = fontFamily),
            displaySmall = displaySmall.copy(fontFamily = fontFamily),
            headlineLarge = headlineLarge.copy(fontFamily = fontFamily),
            headlineMedium = headlineMedium.copy(fontFamily = fontFamily),
            headlineSmall = headlineSmall.copy(fontFamily = fontFamily),
            titleLarge = titleLarge.copy(fontFamily = fontFamily),
            titleMedium = titleMedium.copy(fontFamily = fontFamily),
            titleSmall = titleSmall.copy(fontFamily = fontFamily),
            bodyLarge = bodyLarge.copy(fontFamily =  fontFamily),
            bodyMedium = bodyMedium.copy(fontFamily = fontFamily),
            bodySmall = bodySmall.copy(fontFamily = fontFamily),
            labelLarge = labelLarge.copy(fontFamily = fontFamily),
            labelMedium = labelMedium.copy(fontFamily = fontFamily),
            labelSmall = labelSmall.copy(fontFamily = fontFamily)
        )
    }
}
