@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package dev.subfly.yaba.core.managers

import dev.subfly.yaba.core.common.CoreConstants
import dev.subfly.yaba.core.database.DatabaseProvider
import dev.subfly.yaba.core.filesystem.access.FileAccessProvider
import dev.subfly.yaba.core.queue.CoreOperationQueue
import dev.subfly.yaba.core.unfurl.ReadableAsset
import dev.subfly.yaba.core.unfurl.ReadableUnfurl
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext

/**
 * Filesystem + Room manager for a single current readable per link bookmark, and
 * [readable/current.json] mirroring for notemarks and docmark placeholders.
 */
object ReadableContentManager {
    private val linkBookmarkDao get() = DatabaseProvider.linkBookmarkDao
    private val accessProvider = FileAccessProvider

    fun saveReadableContent(bookmarkId: String, readable: ReadableUnfurl) {
        CoreOperationQueue.queue("SaveReadable:$bookmarkId") {
            upsertLinkReadableInternal(bookmarkId, readable)
        }
    }

    /** Suspending save used from creation and tests. */
    suspend fun saveReadableContentAwait(bookmarkId: String, readable: ReadableUnfurl) {
        CoreOperationQueue.queueAndAwait("SaveReadable:$bookmarkId") {
            upsertLinkReadableInternal(bookmarkId, readable)
        }
    }

    private suspend fun upsertLinkReadableInternal(bookmarkId: String, readable: ReadableUnfurl) {
        val assetRelPaths = saveAssets(bookmarkId, readable.assets)
        val bodyRel = CoreConstants.FileSystem.Linkmark.readableCurrentDocumentPath(bookmarkId)
        val file = accessProvider.resolveRelativePath(bodyRel, ensureParentExists = true)
        withContext(Dispatchers.IO) {
            file.write(readable.documentJson.encodeToByteArray())
        }
        val existing = linkBookmarkDao.getByBookmarkId(bookmarkId)
            ?: error("link_bookmarks row missing for $bookmarkId")
        linkBookmarkDao.upsert(
            existing.copy(
                readableBodyRelativePath = bodyRel,
                readableAssetRelativePaths = assetRelPaths,
            ),
        )
    }

    private suspend fun saveAssets(
        bookmarkId: String,
        assets: List<ReadableAsset>,
    ): List<String> {
        val out = ArrayList<String>(assets.size)
        for (asset in assets) {
            val relativePath = CoreConstants.FileSystem.Linkmark.assetPath(
                bookmarkId,
                asset.assetId,
                asset.extension,
            )
            val file = accessProvider.resolveRelativePath(relativePath, ensureParentExists = true)
            if (!file.exists()) {
                withContext(Dispatchers.IO) {
                    file.write(asset.bytes)
                }
            }
            out.add(relativePath)
        }
        return out
    }

    /**
     * Docmarks: ensure `readable/current.json` exists when only PDF is present.
     */
    fun ensureDocmarkReadablePlaceholderIfNeeded(bookmarkId: String) {
        CoreOperationQueue.queue("EnsureDocmarkReadable:$bookmarkId") {
            ensureDocmarkReadablePlaceholderInternal(bookmarkId)
        }
    }

    private suspend fun ensureDocmarkReadablePlaceholderInternal(bookmarkId: String) {
        val rel = CoreConstants.FileSystem.Linkmark.readableCurrentDocumentPath(bookmarkId)
        val file = accessProvider.resolveRelativePath(rel, ensureParentExists = true)
        if (file.exists()) return
        val json = """{"type":"doc","content":[]}"""
        withContext(Dispatchers.IO) {
            file.write(json.encodeToByteArray())
        }
    }

    /**
     * Writes notemark/editor JSON to the same canonical readable path (highlight mirror).
     */
    suspend fun syncReadableDocumentMirror(
        bookmarkId: String,
        documentJson: String,
    ) {
        val rel = CoreConstants.FileSystem.Linkmark.readableCurrentDocumentPath(bookmarkId)
        val file = accessProvider.resolveRelativePath(rel, ensureParentExists = true)
        withContext(Dispatchers.IO) {
            file.write(documentJson.encodeToByteArray())
        }
    }

    /**
     * Observes the current readable for a **link** bookmark: link row + file body.
     */
    fun observeLinkReadable(
        bookmarkId: String,
    ): Flow<LinkmarkReadableView?> {
        return linkBookmarkDao.observeByBookmarkId(bookmarkId)
            .flatMapLatest { link ->
                flow {
                    if (link == null) {
                        emit(null)
                        return@flow
                    }
                    val rel = link.readableBodyRelativePath
                    if (rel == null) {
                        emit(null)
                        return@flow
                    }
                    val body = readVersionByPath(rel)
                    emit(
                        LinkmarkReadableView(
                            body = body,
                            assetRelativePaths = link.readableAssetRelativePaths,
                        ),
                    )
                }
            }
    }

    suspend fun readVersionByPath(relativePath: String): String? =
        accessProvider.readText(relativePath)
}

/**
 * TODO: REMOVE
 * In-memory view for the link reader.
 */
data class LinkmarkReadableView(
    val body: String?,
    val assetRelativePaths: List<String>,
)
