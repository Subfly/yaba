package core.components.layout

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.ChevronLeft
import androidx.compose.material.icons.twotone.ChevronRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.localization.LocalizationStateProvider
import core.theme.ThemeStateProvider
import core.util.selections.ColorSelection

@Composable
fun YabaColorSelectionLayout(
    label: String,
    isPrimary: Boolean = true,
    onColorChange: (ColorSelection) -> Unit,
    modifier: Modifier = Modifier
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    val selectable by remember {
        derivedStateOf {
            ColorSelection.entries
        }
    }
    var currentIndex by remember {
        mutableStateOf(
            if (isPrimary) 0 else 1
        )
    }

    LaunchedEffect(currentIndex) {
        onColorChange(
            selectable[currentIndex]
        )
    }

    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
        )
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Icon(
                modifier = Modifier
                    .size(24.dp)
                    .clickable {
                        if (currentIndex > 0) {
                            currentIndex -= 1
                        }
                    },
                imageVector = Icons.TwoTone.ChevronLeft,
                contentDescription = localizationProvider.accessibility.PREVIOUS_SELECTION_ICON_DESCRIPTION,
                tint = themeState.colors.onBackground,
            )
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(
                        color = selectable[currentIndex].color,
                        shape = CircleShape
                    )
            )
            Icon(
                modifier = Modifier
                    .size(24.dp)
                    .clickable {
                        if (currentIndex < selectable.size - 1) {
                            currentIndex += 1
                        }
                    },
                imageVector = Icons.TwoTone.ChevronRight,
                contentDescription = localizationProvider.accessibility.NEXT_SELECTION_ICON_DESCRIPTION,
                tint = themeState.colors.onBackground,
            )
        }
    }
}
