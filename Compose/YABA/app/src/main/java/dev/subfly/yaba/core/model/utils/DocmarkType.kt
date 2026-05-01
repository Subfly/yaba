package dev.subfly.yaba.core.model.utils

/**
 * Stored on [dev.subfly.yaba.core.database.entities.DocBookmarkEntity] for FILE bookmarks.
 * PDF only; legacy "EPUB" database values are coerced to [DocmarkType.PDF] via [CoreTypeConverters.stringToDocmarkType].
 */
enum class DocmarkType {
    PDF;

    companion object {
        fun fromFileExtension(extension: String): DocmarkType? =
            when (extension.lowercase().removePrefix(".")) {
                "pdf" -> PDF
                else -> null
            }
    }
}
