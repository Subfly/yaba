package view.mobile.home.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.ExpandMore
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.text.font.FontWeight
import core.localization.LocalizationStateProvider

@Composable
fun HomeTitle(
    title: String,
    expanded: Boolean,
    onClick: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val localizationProvider = LocalizationStateProvider.current
    val expandingAnimation by animateFloatAsState(
        targetValue = if (expanded) -180f else 0f,
    )

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            fontWeight = FontWeight.Medium,
            style = MaterialTheme.typography.titleLarge,
        )
        Icon(
            modifier = Modifier
                .rotate(expandingAnimation)
                .clickable {
                    onClick.invoke(expanded.not())
                },
            imageVector = Icons.TwoTone.ExpandMore,
            contentDescription = localizationProvider.accessibility.EXPAND_ICON_DESCRIPTION,
        )
    }
}