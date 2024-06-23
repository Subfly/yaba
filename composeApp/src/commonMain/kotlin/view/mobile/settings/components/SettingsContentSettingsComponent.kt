package view.mobile.settings.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.ChevronRight
import androidx.compose.material.icons.twotone.Lock
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.layout.YabaCard
import core.settings.contentview.ContentViewStyleStateProvider
import core.settings.localization.LocalizationStateProvider

@Composable
fun SettingsContentSettingsComponent(
    modifier: Modifier = Modifier,
    onClickChangeContentViewStyle: () -> Unit,
) {
    val currentViewStyleState = ContentViewStyleStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.Start,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = localizationProvider.localization.CONTENT_OPTIONS,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Medium,
        )
        YabaCard(
            modifier = Modifier.fillMaxWidth(),
            requireBorder = false,
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp)
                        .clip(shape = RoundedCornerShape(8.dp))
                        .clickable(onClick = onClickChangeContentViewStyle)
                        .padding(vertical = 16.dp)
                        .padding(bottom = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = currentViewStyleState.currentStyle.icon,
                            contentDescription = currentViewStyleState.currentStyle.getDescription(
                                accessibility = localizationProvider.accessibility,
                            ),
                        )
                        Text(
                            text = localizationProvider.localization.CONTENT_VIEW_SELECTION_OPTION,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    Text(
                        text = currentViewStyleState.currentStyle.getUIText(
                            localization = localizationProvider.localization,
                        )
                    )
                }
                HorizontalDivider(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp)
                )
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp)
                        .clip(shape = RoundedCornerShape(8.dp))
                        .clickable(onClick = { /* TODO: ADD FUNCTIONALITY */})
                        .padding(vertical = 16.dp)
                        .padding(top = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.TwoTone.Lock,
                            contentDescription = localizationProvider.accessibility.PRIVATE_CONTENT_LOCK_ICON_DESCRIPTION,
                            // TODO: ADD TINT
                        )
                        Text(
                            text = localizationProvider.localization.SETTINGS_PRIVATE_CONTENT_PASSWORD_TITLE,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    Icon(
                        imageVector = Icons.TwoTone.ChevronRight,
                        contentDescription = localizationProvider.accessibility.OPEN_OPTIONS_DESCRIPTION,
                        // TODO: ADD TINT
                    )
                }
            }
        }
    }
}
