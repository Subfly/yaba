package dev.subfly.yaba.ui.detail.bookmark.link.layout

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.subfly.yaba.core.navigation.main.FolderDetailRoute
import dev.subfly.yaba.core.navigation.main.TagDetailRoute
import dev.subfly.yaba.ui.detail.bookmark.link.components.LinkmarkDetailActionsContent
import dev.subfly.yaba.ui.detail.bookmark.link.components.LinkmarkDetailImageSectionContent
import dev.subfly.yaba.ui.detail.bookmark.link.components.LinkmarkDetailInfoSectionContent
import dev.subfly.yaba.ui.detail.composables.BookmarkDetailFolderSectionContent
import dev.subfly.yaba.ui.detail.composables.BookmarkDetailReminderSectionContent
import dev.subfly.yaba.ui.detail.composables.BookmarkDetailTagSectionContent
import dev.subfly.yaba.ui.detail.composables.BookmarkExtractedMetadataSection
import dev.subfly.yaba.util.LocalContentNavigator
import dev.subfly.yaba.core.model.utils.YabaColor
import dev.subfly.yaba.core.state.detail.linkmark.LinkmarkDetailEvent
import dev.subfly.yaba.core.state.detail.linkmark.LinkmarkDetailUIState

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun LinkmarkDetailLayout(
    state: LinkmarkDetailUIState,
    onHide: () -> Unit,
    onEvent: (LinkmarkDetailEvent) -> Unit,
) {
    val navigator = LocalContentNavigator.current

    val mainColor by remember(state.bookmark) {
        mutableStateOf(state.bookmark?.parentFolder?.color ?: YabaColor.BLUE)
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxWidth()
            .fillMaxSize(0.9F),
    ) {
        stickyHeader(key = "ACTIONS") {
            LinkmarkDetailActionsContent(
                modifier = Modifier.animateItem(),
                mainColor = mainColor,
                onHide = onHide,
            )
        }
        item { Spacer(modifier = Modifier.height(18.dp)) }
        state.bookmark?.let { bookmarkDetails ->
            item(key = "LINK_IMAGE") {
                LinkmarkDetailImageSectionContent(
                    modifier = Modifier.animateItem(),
                    bookmarkDetails = bookmarkDetails,
                    linkDetails = state.linkDetails,
                    mainColor = mainColor,
                )
            }
            item { Spacer(modifier = Modifier.height(24.dp)) }
            item(key = "LINK_INFO") {
                LinkmarkDetailInfoSectionContent(
                    modifier = Modifier.animateItem(),
                    bookmarkDetails = bookmarkDetails,
                    mainColor = mainColor,
                )
            }
            item(key = "LINK_METADATA") {
                state.linkDetails?.let { link ->
                    BookmarkExtractedMetadataSection(
                        modifier = Modifier.animateItem(),
                        mainColor = mainColor,
                        metadataTitle = link.metadataTitle,
                        metadataDescription = link.metadataDescription,
                        metadataAuthor = link.metadataAuthor,
                        metadataDate = link.metadataDate,
                        audioUrl = link.audioUrl,
                        videoUrl = link.videoUrl,
                    )
                }
            }
            item { Spacer(modifier = Modifier.height(24.dp)) }
            bookmarkDetails.parentFolder?.let { folder ->
                item(key = "FOLDER") {
                    BookmarkDetailFolderSectionContent(
                        modifier = Modifier.animateItem(),
                        folder = folder,
                        mainColor = mainColor,
                        onClickFolder = { navigator.add(FolderDetailRoute(folderId = folder.id)) },
                    )
                }
            }
            item { Spacer(modifier = Modifier.height(24.dp)) }
            item(key = "TAGS") {
                BookmarkDetailTagSectionContent(
                    modifier = Modifier.animateItem(),
                    tags = bookmarkDetails.tags,
                    onClickTag = { tag -> navigator.add(TagDetailRoute(tagId = tag.id)) },
                )
            }
            state.reminderDateEpochMillis?.let { reminderMillis ->
                item { Spacer(modifier = Modifier.height(24.dp)) }
                item(key = "REMINDER") {
                    BookmarkDetailReminderSectionContent(
                        modifier = Modifier.animateItem(),
                        reminderDateEpochMillis = reminderMillis,
                        mainColor = mainColor,
                        onCancelReminder = { onEvent(LinkmarkDetailEvent.OnCancelReminder) },
                    )
                }
            }
            item(key = "EXTRA_SPACER") { Spacer(modifier = Modifier.height(56.dp)) }
        }
    }
}
