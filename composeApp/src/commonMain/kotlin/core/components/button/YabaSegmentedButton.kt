package core.components.button

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRowScope
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import core.settings.theme.ThemeStateProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SingleChoiceSegmentedButtonRowScope.YabaSegmentedButton(
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: @Composable () -> Unit = { SegmentedButtonDefaults.Icon(selected) },
    label: @Composable () -> Unit,
) {
    val themeState = ThemeStateProvider.current

    SegmentedButton(
        selected = selected,
        onClick = onClick,
        modifier = modifier,
        icon = icon,
        label = label,
        shape = RoundedCornerShape(8.dp),
        colors = SegmentedButtonDefaults.colors().copy(
            activeContainerColor = themeState.colors.primary,
            activeContentColor = themeState.colors.onPrimary,
            activeBorderColor = themeState.colors.primary,
            inactiveContainerColor = Color.Transparent,
            inactiveContentColor = themeState.colors.onBackground,
            inactiveBorderColor = themeState.colors.onBackground,
        ),
    )
}