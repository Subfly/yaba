package view.mobile.settings.components.sheet

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.button.YabaRadioButton
import core.components.layout.YabaModalSheet
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.selections.LanguageSelection
import core.util.selections.ThemeSelection

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun SettingsOptionsSheet(
    type: SettingsSheetType,
    sheetState: SheetState,
    modifier: Modifier = Modifier,
    onClickLanguage: (LanguageSelection) -> Unit,
    onClickTheme: (ThemeSelection) -> Unit,
    onDismissRequest: () -> Unit,
) {
    YabaModalSheet(
        modifier = modifier.fillMaxWidth(),
        sheetState = sheetState,
        onDismissRequest = onDismissRequest,
    ) {
        when (type) {
            SettingsSheetType.LANGUAGE -> LanguageSelectionContent(
                onClickLanguage = onClickLanguage,
            )

            SettingsSheetType.THEME -> ThemeSelectionComponent(
                onClickTheme = onClickTheme,
            )
            SettingsSheetType.NONE -> Box(modifier = Modifier)
        }
    }
}

@Composable
private fun LanguageSelectionContent(
    modifier: Modifier = Modifier,
    onClickLanguage: (LanguageSelection) -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(32.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.Start,
    ) {
        Text(
            modifier = Modifier.padding(bottom = 32.dp),
            text = localizationProvider.localization.LANGUAGE_SELECTION_OPTION,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold,
        )
        LanguageSelection.entries.forEach { selection ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(shape = RoundedCornerShape(8.dp))
                    .clickable { onClickLanguage.invoke(selection) },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                YabaRadioButton(
                    selected = localizationProvider.currentLocal == selection,
                    onClick = { onClickLanguage.invoke(selection) }
                )
                Text(selection.getUIText(localizationProvider.localization))
            }
        }
        Spacer(modifier = Modifier.size(16.dp))
    }
}

@Composable
private fun ThemeSelectionComponent(
    modifier: Modifier = Modifier,
    onClickTheme: (ThemeSelection) -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(32.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.Start,
    ) {
        Text(
            modifier = Modifier.padding(bottom = 32.dp),
            text = localizationProvider.localization.THEME_SELECTION_OPTION,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold,
        )
        ThemeSelection.entries.forEach { selection ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(shape = RoundedCornerShape(8.dp))
                    .clickable { onClickTheme.invoke(selection) },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                YabaRadioButton(
                    selected = themeState.currentSelectedTheme == selection,
                    onClick = { onClickTheme.invoke(selection) }
                )
                Text(selection.getUIText(localizationProvider.localization))
            }
        }
        Spacer(modifier = Modifier.size(16.dp))
    }
}