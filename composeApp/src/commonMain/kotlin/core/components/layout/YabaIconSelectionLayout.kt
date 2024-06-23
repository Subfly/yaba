package core.components.layout

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import core.components.button.YabaIconButton
import core.settings.localization.LocalizationStateProvider
import core.settings.theme.ThemeStateProvider
import core.util.icon.YabaIcons

@Composable
fun YabaIconSelectionLayout(
    modifier: Modifier = Modifier,
    onSelected: (YabaIcons?) -> Unit,
) {
    val themeState = ThemeStateProvider.current
    val localizationProvider = LocalizationStateProvider.current

    var selectedIcon: YabaIcons? by remember { mutableStateOf(null) }
    var query by remember { mutableStateOf("") }
    val icons by remember(query) {
        derivedStateOf {
            if (query.isEmpty()) {
                YabaIcons.entries
            } else {
                YabaIcons.entries.filter { it.key.contains(query) }
            }
        }
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        YabaTextField(
            modifier = Modifier.fillMaxWidth(),
            value = query,
            onValueChange = { query = it },
            label = {
                Text(localizationProvider.localization.SEARCH_FOR_ICON_TEXT)
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.TwoTone.Search,
                    contentDescription = localizationProvider.accessibility.SEARCH_ICON_DESCIPTION,
                )
            }
        )
        LazyVerticalGrid(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp),
            columns = GridCells.Fixed(5),
        ) {
            items(icons) { icon ->
                YabaIconButton(
                    onClick = {
                        selectedIcon = if (selectedIcon == icon) {
                            null
                        } else {
                            icon
                        }
                        onSelected.invoke(selectedIcon)
                    }
                ) {
                    Box(
                        modifier = Modifier
                            .then(
                                if (selectedIcon == icon) {
                                    Modifier.border(
                                        width = 2.dp,
                                        shape = CircleShape,
                                        color = themeState.colors.primary,
                                    )
                                } else {
                                    Modifier
                                }
                            ),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            modifier = Modifier
                                .padding(8.dp)
                                .size(24.dp),
                            imageVector = icon.icon,
                            contentDescription = icon.key,
                        )
                    }
                }
            }
        }
    }
}