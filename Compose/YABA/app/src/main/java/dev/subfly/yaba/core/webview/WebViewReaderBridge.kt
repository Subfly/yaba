package dev.subfly.yaba.core.webview

/**
 * Imperative bridge for reader WebViews (HTML reader shell or PDF): paging and related hooks.
 */
interface WebViewReaderBridge {
    suspend fun getPageCount(): Int = 1

    suspend fun getCurrentPageNumber(): Int = 1

    suspend fun nextPage(): Boolean = false

    suspend fun prevPage(): Boolean = false

    suspend fun getDocumentJson(): String = ""

    /**
     * Rich-text readable shell only: calls `window.YabaEditorBridge.unFocus()`. No-op for PDF.
     */
    suspend fun unFocus() {}

    /**
     * Markdown from `window.YabaEditorBridge.exportMarkdown()` when the rich-text reader is active.
     * PDF reader returns an empty string.
     */
    suspend fun exportReadableMarkdown(): String = ""

    /**
     * Base64 PDF bytes from `window.YabaEditorBridge.startPdfExportJob` / html2pdf.js for the rich-text reader.
     * PDF viewer returns an empty string.
     */
    suspend fun exportReadablePdfBase64(): String = ""
}
