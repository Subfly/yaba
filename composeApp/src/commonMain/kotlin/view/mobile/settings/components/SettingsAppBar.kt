package view.mobile.settings.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.twotone.ArrowBack
import androidx.compose.material.icons.twotone.ArrowBackIosNew
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import core.components.button.YabaIconButton
import core.components.layout.YabaAppBar
import core.localization.LocalizationStateProvider
import currentPlatform

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsAppBar(
    scrollBehavior: TopAppBarScrollBehavior,
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    YabaAppBar(
        modifier = modifier,
        scrollBehavior = scrollBehavior,
        title = {
            Text(localizationProvider.localization.SETTINGS)
        },
        navigationIcon = {
            YabaIconButton(onClick = onClickBack) {
                Icon(
                    imageVector = if (currentPlatform == Platform.IOS)
                        Icons.TwoTone.ArrowBackIosNew
                    else
                        Icons.AutoMirrored.TwoTone.ArrowBack,
                    contentDescription = localizationProvider.accessibility.RETURN_TO_HOME_ICON_DESCRIPTION,
                )
            }
        }
    )
}