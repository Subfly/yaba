//
//  AddMentionSheet.swift
//  YABA
//

import SwiftData
import SwiftUI

/// Builds `yaba-mention://` links for editors.
struct AddMentionSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    let excludeBookmarkId: String

    let accentColor: Color

    @State
    private var linkText = ""

    @State
    private var selectedBookmarkId: String?

    @State
    private var showBookmarkPicker = false

    let onSubmit: (String, String) -> Void

    init(
        excludeBookmarkId: String,
        accentColor: Color = .accentColor,
        onSubmit: @escaping (String, String) -> Void
    ) {
        self.excludeBookmarkId = excludeBookmarkId
        self.accentColor = accentColor
        self.onSubmit = onSubmit
    }

    /// Larger sheet / window chrome on iPad
    private var isPadIdiom: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var presentationHeightDetent: PresentationDetent {
        .fraction(isPadIdiom ? 0.42 : 0.28)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradient(color: accentColor)
                List {
                    TextField("Add Mention Text To Display Label", text: $linkText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        showBookmarkPicker = true
                    } label: {
                        if let bookmarkId = selectedBookmarkId {
                            AddMentionResolvedRowLabel(bookmarkId: bookmarkId)
                        } else {
                            HStack {
                                Text("Add Mention No Bookmark Selected Label")
                                    .foregroundStyle(.primary)
                                Spacer()
                                YabaIconView(bundleKey: "arrow-right-01")
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Mention Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        guard let id = selectedBookmarkId else { return }
                        let mentionUrl = "yaba-mention://\(id)"
                        onSubmit(trimmedLinkText, mentionUrl)
                        dismiss()
                    }
                    .disabled(!canSubmit)
                }
            }
            .sheet(isPresented: $showBookmarkPicker) {
                NavigationStack {
                    SelectBookmarkContent(
                        excludeBookmarkId: excludeBookmarkId
                    ) { pickedId in
                        selectedBookmarkId = pickedId
                        showBookmarkPicker = false
                    }
                }
            }
        }
        #if !targetEnvironment(macCatalyst)
        .presentationDragIndicator(.visible)
        #else
        .frame(width: 600, height: 250)
        .presentationSizing(.fitted)
        #endif
        .presentationDetents([presentationHeightDetent])
    }

    private var trimmedLinkText: String {
        linkText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedLinkText.isEmpty && selectedBookmarkId != nil
    }
}

/// Resolves the picked bookmark using ``PresentableBookmarkListRowContent``.
private struct AddMentionResolvedRowLabel: View {
    let bookmarkId: String

    @Query
    private var bookmarks: [YabaBookmark]

    init(bookmarkId: String) {
        self.bookmarkId = bookmarkId
        let id = bookmarkId
        _bookmarks = Query(
            filter: #Predicate<YabaBookmark> { $0.bookmarkId == id },
            animation: .smooth
        )
    }

    var body: some View {
        if let bookmark = bookmarks.first {
            PresentableBookmarkListRowContent(bookmark: bookmark, showsDisclosureChevron: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                Text("Add Mention No Bookmark Selected Label")
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView()
            }
        }
    }
}
