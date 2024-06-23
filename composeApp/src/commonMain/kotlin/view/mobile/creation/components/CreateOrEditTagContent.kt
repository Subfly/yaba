package view.mobile.creation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.twotone.HelpOutline
import androidx.compose.material.icons.twotone.Title
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import core.components.button.YabaElevatedButton
import core.components.button.YabaIconButton
import core.components.button.YabaTag
import core.components.layout.YabaColorSelectionLayout
import core.components.layout.YabaIconSelectionLayout
import core.components.layout.YabaTextField
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.icon.YabaIcons
import core.util.selections.ColorSelection

@Composable
internal fun CreateOrEditTagContent(
    modifier: Modifier = Modifier,
    onCreate: (
        name: String,
        icon: String?,
        firstColor: String?,
        secondColor: String?,
    ) -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    var isSelected by remember { mutableStateOf(true) }
    var nameFieldValue by remember { mutableStateOf("") }
    var selectedIcon: YabaIcons? by remember { mutableStateOf(null) }
    var selectedFirstColor: ColorSelection by remember {
        mutableStateOf(ColorSelection.PRIMARY)
    }
    var selectedSecondColor: ColorSelection by remember {
        mutableStateOf(ColorSelection.SECONDARY)
    }

    var nameFieldError by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                text = localizationProvider.localization.PREVIEW,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
            YabaIconButton(
                onClick = {
                    // TODO: Show Info Tooltip
                }
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.TwoTone.HelpOutline,
                    contentDescription = localizationProvider.accessibility.HELP_ICON_DESCRIPTION,
                    tint = themeState.colors.onBackground,
                )
            }
        }
        Spacer(modifier = Modifier.size(16.dp))
        YabaTag(
            modifier = Modifier.align(Alignment.CenterHorizontally),
            selected = isSelected,
            name = nameFieldValue.ifEmpty {
                localizationProvider.localization.TAG_NAME
            },
            firstColor = selectedFirstColor.color,
            secondColor = selectedSecondColor.color,
            icon = selectedIcon?.icon,
            iconDescription = selectedIcon?.key,
            onClick = {
                isSelected = isSelected.not()
            },
        )
        Spacer(modifier = Modifier.size(32.dp))
        Text(
            text = localizationProvider.localization.TAG_NAME,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(modifier = Modifier.size(8.dp))
        YabaTextField(
            modifier = Modifier.fillMaxWidth(),
            value = nameFieldValue,
            onValueChange = {
                nameFieldValue = it
                if (nameFieldError && it.isNotBlank()) {
                    nameFieldError = false
                }
            },
            label = {
                Text(localizationProvider.localization.TAG_NAME)
            },
            placeholder = {
                Text(localizationProvider.localization.WRITE_HERE)
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.TwoTone.Title,
                    contentDescription = localizationProvider.accessibility.TITLE_TEXT_FIELD_ICON_DESCRIPTION,
                )
            },
            isError = nameFieldError,
        )
        Spacer(modifier = Modifier.size(16.dp))
        Text(
            text = localizationProvider.localization.COLOR_SELECTION,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(modifier = Modifier.size(8.dp))
        YabaColorSelectionLayout(
            label = localizationProvider.localization.COLOR_SELECTION_FIRST,
            isPrimary = true,
            onColorChange = { selectedColor ->
                selectedFirstColor = selectedColor
            }
        )
        Spacer(modifier = Modifier.size(12.dp))
        YabaColorSelectionLayout(
            label = localizationProvider.localization.COLOR_SELECTION_SECOND,
            isPrimary = false,
            onColorChange = { selectedColor ->
                selectedSecondColor = selectedColor
            },
        )
        Spacer(modifier = Modifier.size(16.dp))
        Text(
            text = localizationProvider.localization.ICON_SELECTION,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(modifier = Modifier.size(8.dp))
        YabaIconSelectionLayout(
            modifier = Modifier.fillMaxWidth(),
            onSelected = { selection ->
                selectedIcon = selection
            },
        )
        Spacer(modifier = Modifier.height(8.dp))
        YabaElevatedButton(
            modifier = Modifier
                .padding(bottom = 16.dp)
                .fillMaxWidth()
                .height(56.dp),
            onClick = {
                if (nameFieldValue.isNotBlank()) {
                    onCreate.invoke(
                        nameFieldValue,
                        selectedIcon?.key,
                        selectedFirstColor.name,
                        selectedSecondColor.name,
                    )
                } else {
                    nameFieldError = true
                }
            },
        ) {
            Text(localizationProvider.localization.CREATE_TAG)
        }
    }
}
