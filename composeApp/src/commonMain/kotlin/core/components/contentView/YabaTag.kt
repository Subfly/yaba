package core.components.contentView

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.settings.theme.ThemeStateProvider
import core.util.selections.ColorSelection

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun YabaTag(
    selected: Boolean,
    name: String?,
    firstColor: Color?,
    secondColor: Color?,
    icon: ImageVector?,
    iconDescription: String?,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
) {
    val themeState = ThemeStateProvider.current

    Row(
        modifier = modifier
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongClick,
            )
            .shadow(
                elevation = if (selected) 4.dp else 0.dp,
                shape = RoundedCornerShape(8.dp),
            )
            .border(
                border = if (selected) {
                    BorderStroke(
                        width = 0.dp,
                        color = Color.Transparent,
                    )
                } else {
                    BorderStroke(
                        width = 2.dp,
                        color = themeState.colors.primary.copy(alpha = 0.8f),
                    )
                },
                shape = RoundedCornerShape(8.dp),
            )
            .then(
                if (selected) {
                    Modifier.background(
                        brush = Brush.linearGradient(
                            colors = listOf(
                                firstColor ?: ColorSelection.PRIMARY.color,
                                secondColor ?: ColorSelection.SECONDARY.color,
                            )
                        ),
                        shape = RoundedCornerShape(8.dp),
                    )
                } else {
                    Modifier.background(
                        color = Color.Transparent,
                    )
                }
            ),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        icon?.let {
            Icon(
                modifier = Modifier
                    .padding(
                        top = if (name == null) 4.dp else 8.dp,
                        bottom = if (name == null) 4.dp else 8.dp,
                        start = if (name == null) 4.dp else 12.dp,
                        end = if (name == null) 4.dp else 0.dp,
                    ).then(
                        if (name == null)
                            Modifier.size(22.dp)
                        else
                            Modifier
                    ),
                imageVector = it,
                contentDescription = iconDescription,
                tint = with(themeState.colors) {
                    if (selected) creamyWhite else onBackground
                },
            )
        }
        name?.let {
            Text(
                modifier = Modifier.padding(
                    top = 8.dp,
                    bottom = 8.dp,
                    end = 12.dp,
                    start = if (icon != null) 0.dp else 12.dp,
                ),
                text = it,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium,
                color = with(themeState.colors) {
                    if (selected) creamyWhite else onBackground
                },
            )
        }
    }
}
