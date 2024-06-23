package core.components.contentView.grid

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onPlaced
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import coil3.compose.SubcomposeAsyncImage
import core.components.layout.YabaCard
import core.model.TagModel
import kotlinx.datetime.LocalDateTime

@Composable
fun YabaBookmarkCard(
    modifier: Modifier = Modifier,
    title: String,
    dateAdded: LocalDateTime,
    tags: List<TagModel>,
    isPrivate: Boolean,
    imageUrl: String?,
    imageAspectRatio: Float? = null,
    onClickBookmark: () -> Unit,
) {
    val density = LocalDensity.current
    var onPlacedWidth by remember { mutableStateOf(0) }

    YabaCard(
        modifier = modifier,
        onClick = onClickBookmark,
    ) {
        Column(
            modifier = Modifier
                .padding(16.dp)
        ) {
            // TODO: GET FROM ACCESSIBILITY
            SubcomposeAsyncImage(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(shape = RoundedCornerShape(8.dp))
                    .onPlaced {
                        onPlacedWidth = it.size.width
                    },
                model = imageUrl,
                contentDescription = "Url Image",
                loading = {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(
                                height = if (imageAspectRatio == null){
                                    120.dp
                                }
                                else {
                                    with(density) {
                                        (onPlacedWidth / imageAspectRatio).toDp()
                                    }
                                }
                            )
                            .background(
                                color = Color.Gray,
                            )
                    )
                },
                error = {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(
                                height = if (imageAspectRatio == null){
                                    120.dp
                                }
                                else {
                                    with(density) {
                                        (onPlacedWidth / imageAspectRatio).toDp()
                                    }
                                }
                            )
                            .background(
                                color = Color.Red,
                            ),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("Resim Yüklenemedi!")
                    }
                }
            )
        }
    }
}
