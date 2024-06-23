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
import androidx.compose.material.icons.automirrored.twotone.Help
import androidx.compose.material.icons.twotone.Description
import androidx.compose.material.icons.twotone.Link
import androidx.compose.material.icons.twotone.Title
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import core.components.contentView.grid.YabaBookmarkCard
import core.components.layout.YabaTextField
import core.settings.theme.ThemeStateProvider
import core.util.extensions.isValidUrl
import core.util.selections.ContentViewSelection
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import unfurl.UnfurlingUtil
import unfurl.models.UnfurlModel

@Composable
internal fun CreateOrEditBookmarkContent(modifier: Modifier = Modifier) {
    val themeState = ThemeStateProvider.current

    var urlFieldValue by remember { mutableStateOf("") }
    var nameFieldValue by remember { mutableStateOf("") }
    var descriptionFieldValue by remember { mutableStateOf("") }
    var currentContentViewSelection by remember {
        mutableStateOf(ContentViewSelection.GRID)
    }
    var unfurlData: UnfurlModel by remember {
        mutableStateOf(UnfurlModel.None)
    }

    LaunchedEffect(urlFieldValue) {
        if (urlFieldValue.isNotEmpty() && urlFieldValue.isValidUrl()) {
            unfurlData = UnfurlingUtil.getUnfurledMetadata(urlFieldValue)
        }
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
    ) {
        Text(unfurlData.toString())
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                "Ön İzleme",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                YabaIconButton(
                    onClick = {
                        currentContentViewSelection =
                            if (currentContentViewSelection == ContentViewSelection.GRID) {
                                ContentViewSelection.LIST
                            } else {
                                ContentViewSelection.GRID
                            }
                    }
                ) {
                    // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                    Icon(
                        imageVector = currentContentViewSelection.icon,
                        contentDescription = "",
                        tint = themeState.colors.onBackground,
                    )
                }
                YabaIconButton(
                    onClick = {
                        // TODO: SHOW INFO
                    }
                ) {
                    // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                    Icon(
                        imageVector = Icons.AutoMirrored.TwoTone.Help,
                        contentDescription = "",
                        tint = themeState.colors.onBackground,
                    )
                }
            }
        }
        Spacer(modifier = Modifier.size(16.dp))
        YabaBookmarkCard(
            title = "Lele",
            dateAdded = Clock.System.now().toLocalDateTime(
                timeZone = TimeZone.currentSystemDefault(),
            ),
            tags = emptyList(),
            isPrivate = false,
            imageUrl = (unfurlData as? UnfurlModel.Success)?.twitterModel?.imageUrl,
            onClickBookmark = {},
        )
        Spacer(modifier = Modifier.size(32.dp))
        // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
        Text(
            text = "Kayıt Linki",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(modifier = Modifier.size(8.dp))
        YabaTextField(
            modifier = Modifier.fillMaxWidth(),
            value = urlFieldValue,
            onValueChange = { urlFieldValue = it },
            // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
            label = {
                Text("Kayıt Linki")
            },
            // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
            placeholder = {
                Text("Buraya yazın...")
            },
            leadingIcon = {
                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                Icon(
                    imageVector = Icons.TwoTone.Link,
                    contentDescription = ""
                )
            }
        )
        Spacer(modifier = Modifier.size(16.dp))
        // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
        Text(
            text = "Kayıt Adı",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(modifier = Modifier.size(8.dp))
        YabaTextField(
            modifier = Modifier.fillMaxWidth(),
            value = nameFieldValue,
            onValueChange = { nameFieldValue = it },
            // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
            label = {
                Text("Kayıt Adı")
            },
            // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
            placeholder = {
                Text("Buraya yazın...")
            },
            leadingIcon = {
                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                Icon(
                    imageVector = Icons.TwoTone.Title,
                    contentDescription = ""
                )
            }
        )
        Spacer(modifier = Modifier.size(16.dp))
        Text(
            text = "Kayıt Açıklaması",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(modifier = Modifier.size(8.dp))
        YabaTextField(
            modifier = Modifier.fillMaxWidth(),
            value = descriptionFieldValue,
            onValueChange = { descriptionFieldValue = it },
            // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
            label = {
                Text("Kayıt Açıklaması")
            },
            // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
            placeholder = {
                Text("Buraya yazın...")
            },
            leadingIcon = {
                // TODO: GET FROM ACCESSIBILITY AND LOCALIZATION PROVIDERS
                Icon(
                    imageVector = Icons.TwoTone.Description,
                    contentDescription = ""
                )
            }
        )
        Spacer(modifier = Modifier.height(32.dp))
        YabaElevatedButton(
            modifier = Modifier
                .padding(bottom = 16.dp)
                .fillMaxWidth()
                .height(56.dp),
            onClick = {

            },
        ) {
            Text("Kayıt Oluştur")
        }
    }
}
