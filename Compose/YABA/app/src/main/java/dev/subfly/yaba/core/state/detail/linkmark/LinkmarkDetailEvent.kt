package dev.subfly.yaba.core.state.detail.linkmark

import dev.subfly.yaba.core.model.utils.ReaderFontSize
import dev.subfly.yaba.core.model.utils.ReaderLineHeight
import dev.subfly.yaba.core.model.utils.ReaderTheme
import dev.subfly.yaba.core.webview.WebShellLoadResult

sealed interface LinkmarkDetailEvent {
    data class OnInit(val bookmarkId: String) : LinkmarkDetailEvent
    data class OnReaderWebInitialContentLoad(val result: WebShellLoadResult) : LinkmarkDetailEvent
    data object OnDeleteBookmark : LinkmarkDetailEvent
    data object OnToggleReaderTheme : LinkmarkDetailEvent
    data object OnToggleReaderFontSize : LinkmarkDetailEvent
    data object OnToggleReaderLineHeight : LinkmarkDetailEvent
    data class OnSetReaderTheme(val theme: ReaderTheme) : LinkmarkDetailEvent
    data class OnSetReaderFontSize(val fontSize: ReaderFontSize) : LinkmarkDetailEvent
    data class OnSetReaderLineHeight(val lineHeight: ReaderLineHeight) : LinkmarkDetailEvent
    data object OnRequestNotificationPermission : LinkmarkDetailEvent
    data class OnScheduleReminder(
        val selectedDateMillis: Long,
        val hour: Int,
        val minute: Int,
        val title: String,
        val message: String,
    ) : LinkmarkDetailEvent
    data object OnCancelReminder : LinkmarkDetailEvent
    data class OnExportMarkdownReady(val markdown: String) : LinkmarkDetailEvent
    data class OnExportPdfReady(val pdfBase64: String) : LinkmarkDetailEvent
}
