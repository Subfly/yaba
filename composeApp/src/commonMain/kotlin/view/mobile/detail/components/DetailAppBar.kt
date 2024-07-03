package view.mobile.detail.components

import Platform
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.twotone.ArrowBack
import androidx.compose.material.icons.twotone.ArrowBackIosNew
import androidx.compose.material.icons.twotone.Delete
import androidx.compose.material.icons.twotone.Edit
import androidx.compose.material.icons.twotone.MoreVert
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import core.components.button.YabaIconButton
import core.components.layout.YabaAppBar
import core.components.layout.YabaMenu
import core.components.layout.YabaMenuItem
import core.components.layout.YabaProgressIndicator
import core.settings.localization.LocalizationStateProvider
import currentPlatform

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailAppBar(
    title: String,
    isLoading: Boolean,
    scrollBehavior: TopAppBarScrollBehavior,
    firstColor: Color,
    secondColor: Color,
    icon: ImageVector,
    iconDescription: String,
    modifier: Modifier = Modifier,
    onClickBack: () -> Unit,
    onClickEdit: () -> Unit,
    onClickDelete: () -> Unit,
) {
    val localizationState = LocalizationStateProvider.current

    var isMenuExpanded by remember { mutableStateOf(false) }

    Column(modifier = modifier.fillMaxWidth()) {
        YabaAppBar(
            modifier = Modifier.background(
                brush = Brush.linearGradient(
                    colors = listOf(firstColor, secondColor),
                )
            ),
            navigationIcon = {
                YabaIconButton(onClick = onClickBack) {
                    Icon(
                        imageVector = if (currentPlatform == Platform.IOS)
                            Icons.TwoTone.ArrowBackIosNew
                        else
                            Icons.AutoMirrored.TwoTone.ArrowBack,
                        contentDescription = localizationState.accessibility.RETURN_TO_HOME_ICON_DESCRIPTION,
                    )
                }
            },
            title = {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(text = title)
                    Icon(
                        imageVector = icon,
                        contentDescription = iconDescription,
                    )
                }
            },
            actions = {
                YabaIconButton(
                    onClick = { isMenuExpanded = true },
                ) {
                    Icon(
                        imageVector = Icons.TwoTone.MoreVert,
                        contentDescription = localizationState.accessibility.SHOW_MORE_ICON_DESCRIPTION
                    )
                }
                YabaMenu(
                    expanded = isMenuExpanded,
                    onDismissRequest = {
                        isMenuExpanded = false
                    },
                ) {
                    YabaMenuItem(
                        text = {
                            Text(localizationState.localization.EDIT_TITLE)
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.TwoTone.Edit,
                                contentDescription = localizationState.accessibility.EDIT_ICON_DESCRIPTION,
                            )
                        },
                        onClick = {
                            isMenuExpanded = false
                            onClickEdit.invoke()
                        },
                    )
                    YabaMenuItem(
                        text = {
                            Text(localizationState.localization.DELETE_TITLE)
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.TwoTone.Delete,
                                contentDescription = localizationState.accessibility.DELETE_ICON_DESCRIPTION,
                            )
                        },
                        onClick = {
                            isMenuExpanded = false
                            onClickDelete.invoke()
                        },
                    )
                }
            },
            scrollBehavior = scrollBehavior,
        )
        if (isLoading) {
            YabaProgressIndicator()
        }
    }
}
