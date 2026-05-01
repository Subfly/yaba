package dev.subfly.yaba.ui.detail.bookmark.doc.layout

import androidx.compose.ui.res.stringResource

import dev.subfly.yaba.R

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.CircularWavyProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import dev.subfly.yaba.core.components.NoContentView
import dev.subfly.yaba.core.components.YabaIcon
import dev.subfly.yaba.core.components.webview.YabaWebView
import dev.subfly.yaba.ui.detail.bookmark.components.BookmarkDetailContentTopBar
import dev.subfly.yaba.ui.detail.bookmark.components.bookmarkFolderAccentColor
import dev.subfly.yaba.ui.detail.bookmark.doc.components.DocmarkContentDropdownMenu
import dev.subfly.yaba.ui.detail.bookmark.doc.components.DocmarkReaderFloatingToolbar
import dev.subfly.yaba.ui.detail.bookmark.util.bookmarkDetailIconButtonColors
import dev.subfly.yaba.util.LocalContentNavigator
import dev.subfly.yaba.core.state.detail.DetailWebShellPhase
import dev.subfly.yaba.core.state.detail.docmark.DocmarkDetailEvent
import dev.subfly.yaba.core.state.detail.docmark.detailWebShellPhase
import dev.subfly.yaba.core.state.detail.docmark.DocmarkDetailUIState
import dev.subfly.yaba.core.webview.WebComponentUris
import dev.subfly.yaba.core.webview.WebViewReaderBridge
import dev.subfly.yaba.core.webview.YabaWebAppearance
import dev.subfly.yaba.core.webview.YabaWebFeature
import dev.subfly.yaba.core.webview.YabaWebHostEvent
import dev.subfly.yaba.core.webview.YabaWebPlatform
import dev.subfly.yaba.core.webview.YabaWebScrollDirection
import kotlinx.coroutines.launch

private data class ReaderMetricsUiState(
    val currentPage: Int = 1,
    val pageCount: Int = 1,
)

@OptIn(
    ExperimentalMaterial3Api::class,
    ExperimentalMaterial3ExpressiveApi::class,
)
@Composable
internal fun DocmarkContentLayout(
    modifier: Modifier = Modifier,
    state: DocmarkDetailUIState,
    onShowDetail: () -> Unit,
    onEvent: (DocmarkDetailEvent) -> Unit,
    onShowRemindMePicker: () -> Unit = {},
) {
    val navigator = LocalContentNavigator.current
    val scope = rememberCoroutineScope()

    var readerBridge by remember { mutableStateOf<WebViewReaderBridge?>(null) }
    val appearance = if (isSystemInDarkTheme()) YabaWebAppearance.Dark else YabaWebAppearance.Light
    val hasDocumentPath = !state.documentAbsolutePath.isNullOrBlank()
    val webShellPhase = remember(
        state.isLoading,
        state.documentAbsolutePath,
        state.webContentLoadFailed,
    ) { state.detailWebShellPhase() }
    var isMenuExpanded by remember { mutableStateOf(false) }
    var readerMetrics by remember { mutableStateOf(ReaderMetricsUiState()) }
    var isToolbarVisible by remember { mutableStateOf(true) }

    val documentPath = state.documentAbsolutePath ?: ""
    val folderAccent = remember(state.bookmark) { bookmarkFolderAccentColor(state.bookmark) }
    val menuIconButtonColors = bookmarkDetailIconButtonColors(folderAccent)
    val webBaseUrl = remember { WebComponentUris.getPdfViewerUri() }
    val webFeature = remember(
        documentPath,
        appearance,
    ) {
        YabaWebFeature.PdfViewer(
            pdfUrl = documentPath,
            platform = YabaWebPlatform.Android,
            appearance = appearance,
        )
    }

    LaunchedEffect(hasDocumentPath) {
        if (!hasDocumentPath) {
            readerMetrics = ReaderMetricsUiState()
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(color = MaterialTheme.colorScheme.background),
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            when (webShellPhase) {
                DetailWebShellPhase.Loading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) { CircularWavyProgressIndicator() }
                }

                DetailWebShellPhase.Unavailable -> {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.surface,
                    ) {
                        NoContentView(
                            modifier = Modifier
                                .fillMaxSize()
                                .wrapContentSize(Alignment.Center),
                            iconName = "cancel-square",
                            labelRes = R.string.reader_not_available_title,
                        ) {
                            Text(text = stringResource(R.string.reader_not_available_description))
                        }
                    }
                }

                DetailWebShellPhase.Bootstrapping,
                DetailWebShellPhase.Ready -> {
                    if (webShellPhase == DetailWebShellPhase.Ready) {
                        DocmarkReaderFloatingToolbar(
                            modifier = Modifier.padding(bottom = 8.dp),
                            color = folderAccent,
                            isVisible = isToolbarVisible,
                            canGoPrev = readerMetrics.currentPage > 1,
                            canGoNext = readerMetrics.currentPage < readerMetrics.pageCount,
                            onPrevPage = {
                                scope.launch {
                                    readerBridge?.prevPage()
                                }
                            },
                            onNextPage = {
                                scope.launch {
                                    readerBridge?.nextPage()
                                }
                            },
                        )
                    }

                    Box(modifier = Modifier.fillMaxSize()) {
                        YabaWebView(
                            modifier = Modifier.fillMaxSize(),
                            baseUrl = webBaseUrl,
                            feature = webFeature,
                            onHostEvent = { ev ->
                                when (ev) {
                                    is YabaWebHostEvent.ReaderMetrics -> {
                                        val nextMetrics =
                                            ReaderMetricsUiState(
                                                currentPage = ev.currentPage,
                                                pageCount = ev.pageCount.coerceAtLeast(1),
                                            )
                                        if (readerMetrics != nextMetrics) {
                                            readerMetrics = nextMetrics
                                        }
                                    }

                                    is YabaWebHostEvent.InitialContentLoad ->
                                        onEvent(DocmarkDetailEvent.OnWebInitialContentLoad(ev.result))

                                    else -> Unit
                                }
                            },
                            onScrollDirectionChanged = { direction ->
                                isToolbarVisible = when (direction) {
                                    YabaWebScrollDirection.Down -> false
                                    YabaWebScrollDirection.Up -> true
                                }
                            },
                            onReaderBridgeReady = { bridge -> readerBridge = bridge },
                        )
                        if (webShellPhase == DetailWebShellPhase.Bootstrapping) {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center,
                            ) { CircularWavyProgressIndicator() }
                        }
                    }
                }
            }
        }

        Column(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .fillMaxWidth(),
        ) {
            BookmarkDetailContentTopBar(
                color = folderAccent,
                onBack = navigator::removeLastOrNull,
                onShowDetail = onShowDetail,
                overflowMenu = {
                    Box(modifier = Modifier.wrapContentSize(Alignment.TopStart)) {
                        IconButton(
                            onClick = { isMenuExpanded = !isMenuExpanded },
                            colors = menuIconButtonColors,
                            shapes = IconButtonDefaults.shapes(),
                        ) { YabaIcon(name = "more-horizontal-circle-02", color = Color.White) }

                        DocmarkContentDropdownMenu(
                            expanded = isMenuExpanded,
                            onDismissRequest = { isMenuExpanded = false },
                            state = state,
                            onEvent = onEvent,
                            onShowRemindMePicker = onShowRemindMePicker,
                        )
                    }
                },
                loadingIndicator = {},
            )
        }
    }
}
