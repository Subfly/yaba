package core.components.button

import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import core.theme.ThemeStateProvider

@Composable
fun YabaRadioButton(
    selected: Boolean,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    val themeState = ThemeStateProvider.current

    RadioButton(
        selected = selected,
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        colors = RadioButtonDefaults.colors().copy(
            selectedColor = themeState.colors.secondary,
            unselectedColor = themeState.colors.onBackground,
        )
    )
}