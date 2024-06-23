package view.mobile.search

import Platform
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.twotone.ArrowBack
import androidx.compose.material.icons.twotone.ArrowBackIosNew
import androidx.compose.material.icons.twotone.Clear
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import core.components.button.YabaIconButton
import core.components.layout.YabaSearchBarLayout
import core.localization.LocalizationStateProvider
import currentPlatform

@Composable
fun SearchScreen(
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
) {
    val localizationProvider = LocalizationStateProvider.current

    var query by remember { mutableStateOf("") }

    YabaSearchBarLayout(
        modifier = modifier,
        query = query,
        onQueryChange = {
            query = it
        },
        active = true,
        onActiveChange = {},
        onSearch = {},
        leadingIcon = {
            YabaIconButton(onClick = onClickBack) {
                Icon(
                    imageVector = if (currentPlatform == Platform.IOS)
                        Icons.TwoTone.ArrowBackIosNew
                    else
                        Icons.AutoMirrored.TwoTone.ArrowBack,
                    contentDescription = localizationProvider.accessibility.RETURN_TO_HOME_ICON_DESCRIPTION,
                )
            }
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                YabaIconButton(
                    onClick = { query = "" },
                ) {
                    Icon(
                        imageVector = Icons.TwoTone.Clear,
                        contentDescription = localizationProvider.accessibility.CLEAR_SEARCH_FIELD_ICON_DESCRIPTION,
                    )
                }
            }
        },
        placeholder = {
            // TODO: GET FROM LOCALIZATION
            Text(localizationProvider.localization.SEARCH_FIELD_PLACEHOLDER)
        }
    ) {

    }
}
