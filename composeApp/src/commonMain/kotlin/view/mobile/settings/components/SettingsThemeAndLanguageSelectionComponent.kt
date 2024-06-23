package view.mobile.settings.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Translate
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
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider

@Composable
internal fun SettingsThemeAndLanguageSelectionComponent(
    modifier: Modifier = Modifier,
    onClickChangeLanguage: () -> Unit,
    onClickChangeTheme: () -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.Start,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = localizationProvider.localization.THEME_AND_LANGUAGE_OPTIONS,
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
                        .padding(vertical = 16.dp)
                        .padding(bottom = 8.dp)
                        .clip(shape = RoundedCornerShape(8.dp))
                        .clickable(onClick = onClickChangeTheme),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = themeState.currentSelectedTheme.getUIIcon(),
                            contentDescription = themeState.currentSelectedTheme.getDescription(
                                accessibility = localizationProvider.accessibility,
                            ),
                        )
                        Text(
                            text = localizationProvider.localization.THEME_SELECTION_OPTION,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    Text(
                        text = themeState.currentSelectedTheme.getUIText(
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
                        .padding(vertical = 16.dp)
                        .padding(top = 8.dp)
                        .clip(shape = RoundedCornerShape(8.dp))
                        .clickable(onClick = onClickChangeLanguage),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.TwoTone.Translate,
                            contentDescription = localizationProvider.accessibility.SETTINGS_LANGUAGE_ICON_DESCRIPTION,
                            // TODO: ADD TINT
                        )
                        Text(
                            text = localizationProvider.localization.LANGUAGE_SELECTION_OPTION,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    Text(
                        /**
                         * For the one who read this, this is the next
                         * level programming that surprisingly has no
                         * cycling dependency.
                         */
                        text = localizationProvider.currentLocal.getUIText(
                            localization = localizationProvider.localization
                        )
                    )
                }
            }
        }
    }
}