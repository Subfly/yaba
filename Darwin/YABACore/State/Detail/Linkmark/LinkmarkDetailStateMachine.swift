//
//  LinkmarkDetailStateMachine.swift
//  YABACore
//

import Foundation
import SwiftUI

@MainActor
public final class LinkmarkDetailStateMachine: YabaBaseObservableState<LinkmarkDetailUIState>, YabaScreenStateMachine {
    public override init(initialState: LinkmarkDetailUIState = LinkmarkDetailUIState()) {
        super.init(initialState: initialState)
    }

    public func send(_ event: LinkmarkDetailEvent) async {
        switch event {
        case let .onInit(bookmarkId):
            let reminderDate = await ReminderManager.getPendingReminderDate(bookmarkId: bookmarkId)
            let granted = await ReminderManager.authorizationGranted()
            apply {
                $0.bookmarkId = bookmarkId
                $0.reminderDate = reminderDate
                $0.hasNotificationPermission = granted
            }
        case let .onLinkSourceUrl(url):
            apply { $0.linkSourceUrl = url }
        case let .onSaveReadableContent(data):
            guard let bid = state.bookmarkId else { return }
            ReadableContentManager.queueSetLinkReadableDocumentData(bookmarkId: bid, data: data)
        case let .onReaderWebInitialContentLoad(resultJson):
            apply { $0.readerWebInitialLoadResultJson = resultJson }
        case .onDeleteBookmark(let bookmarkId):
            AllBookmarksManager.queueDeleteBookmarks(bookmarkIds: [bookmarkId])
        case .onToggleReaderTheme:
            apply {
                switch $0.readerTheme {
                case .system: $0.readerTheme = .light
                case .light: $0.readerTheme = .dark
                case .dark: $0.readerTheme = .sepia
                case .sepia: $0.readerTheme = .system
                }
            }
        case .onToggleReaderFontSize:
            apply {
                switch $0.readerFontSize {
                case .small: $0.readerFontSize = .medium
                case .medium: $0.readerFontSize = .large
                case .large: $0.readerFontSize = .small
                }
            }
        case .onToggleReaderLineHeight:
            apply {
                $0.readerLineHeight = $0.readerLineHeight == .normal ? .relaxed : .normal
            }
        case let .onSetReaderTheme(t):
            apply { $0.readerTheme = t }
        case let .onSetReaderFontSize(s):
            apply { $0.readerFontSize = s }
        case let .onSetReaderLineHeight(l):
            apply { $0.readerLineHeight = l }
        case .onRequestNotificationPermission:
            _ = await ReminderManager.requestAuthorization()
            let granted = await ReminderManager.authorizationGranted()
            apply { $0.hasNotificationPermission = granted }
            if !granted {
                CoreToastManager.shared.showNotificationPermissionDeniedToast()
            }
        case let .onScheduleReminder(fireAt, titleKey, messageKey):
            guard let bid = state.bookmarkId else { return }
            do {
                try await ReminderManager.scheduleReminderResolvingLabel(
                    bookmarkId: bid,
                    bookmarkKindCode: BookmarkKind.link.rawValue,
                    titleKey: titleKey,
                    messageKey: messageKey,
                    fireAt: fireAt
                )
                apply { $0.reminderDate = fireAt }
                CoreToastManager.shared.showReminderScheduledToast(fireAt: fireAt)
            } catch {
                CoreToastManager.shared.showReminderScheduleFailedToast()
            }
        case .onCancelReminder:
            guard let bid = state.bookmarkId else { return }
            ReminderManager.cancelReminder(bookmarkId: bid)
            apply { $0.reminderDate = nil }
        case let .onExportMarkdownReady(md):
            apply { $0.lastExportMarkdown = md }
        case let .updateLinkMetadata(
            bookmarkId,
            url,
            domain,
            videoUrl,
            audioUrl,
            metadataTitle,
            metadataDescription,
            metadataAuthor,
            metadataDate
        ):
            LinkmarkManager.queueCreateOrUpdateLinkDetails(
                bookmarkId: bookmarkId,
                url: url,
                domain: domain,
                videoUrl: videoUrl,
                audioUrl: audioUrl,
                metadataTitle: metadataTitle,
                metadataDescription: metadataDescription,
                metadataAuthor: metadataAuthor,
                metadataDate: metadataDate
            )
        }
    }

    // MARK: - Sheet & alert bindings (SwiftUI)

    public var showDetailSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showDetailSheet },
            set: { newValue in self.apply { $0.showDetailSheet = newValue } }
        )
    }

    public var showEditSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showEditSheet },
            set: { newValue in self.apply { $0.showEditSheet = newValue } }
        )
    }

    public var showMoveSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showMoveSheet },
            set: { newValue in self.apply { $0.showMoveSheet = newValue } }
        )
    }

    public var showShareURLSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showShareURLSheet },
            set: { newValue in self.apply { $0.showShareURLSheet = newValue } }
        )
    }

    public var showReminderSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showReminderSheet },
            set: { newValue in self.apply { $0.showReminderSheet = newValue } }
        )
    }

    public var showDeleteAlertBinding: Binding<Bool> {
        Binding(
            get: { self.state.showDeleteAlert },
            set: { newValue in self.apply { $0.showDeleteAlert = newValue } }
        )
    }

    public var showActivitySheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showActivitySheet },
            set: { newValue in self.apply { $0.showActivitySheet = newValue } }
        )
    }

    public var showMarkdownExportDirectoryPickerBinding: Binding<Bool> {
        Binding(
            get: { self.state.showMarkdownExportDirectoryPicker },
            set: { newValue in self.apply { $0.showMarkdownExportDirectoryPicker = newValue } }
        )
    }

    // MARK: - Markdown export (UI hands `BookmarkModel`-derived fields; models stay internal to YABACore)

    public func startMarkdownExport(
        markdown: String,
        bookmarkLabel: String,
        inlineSources: [MarkdownExportInlineSource]
    ) {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
            return
        }
        let request = MarkdownExportRequest(
            markdown: trimmed + "\n",
            baseFolderName: ExportSupport.sanitizeBaseFolderName(bookmarkLabel),
            assets: ExportSupport.exportAssets(from: inlineSources)
        )
        apply {
            $0.markdownExportRequest = request
            $0.showMarkdownExportDirectoryPicker = true
        }
    }

    public func finalizeMarkdownExport(selectedDirectory: URL?) {
        let request = state.markdownExportRequest
        apply { $0.markdownExportRequest = nil }
        guard let selectedDirectory, let request else { return }
        let didWrite = ExportSupport.writeBundle(request, into: selectedDirectory)
        if !didWrite {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
        }
    }
}
