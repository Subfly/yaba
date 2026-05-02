//
//  SelectBookmarkContent.swift
//  YABA
//
//  Bookmark picker sheet: searchable SwiftData-backed list mirroring SearchView query semantics.
//

import SwiftData
import SwiftUI

struct SelectBookmarkContent: View {
    @Environment(\.dismiss)
    private var dismiss

    @State
    private var machine = BookmarkSelectionStateMachine()

    @AppStorage(Constants.preferredBookmarkSortingKey)
    private var preferredSorting: SortType = .createdAt

    @AppStorage(Constants.preferredSortOrderKey)
    private var preferredSortOrder: SortOrderType = .ascending

    let excludeBookmarkId: String?

    /// Called with picked bookmark ID; parent should dismiss after if needed — this view also dismisses immediately.
    let onPick: (String) -> Void

    init(
        excludeBookmarkId: String? = nil,
        onPick: @escaping (String) -> Void
    ) {
        self.excludeBookmarkId = excludeBookmarkId
        self.onPick = onPick
    }

    private var trimmedSearch: String {
        machine.state.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var queryListIdentity: String {
        trimmedSearch + "\u{1e}"
            + (excludeBookmarkId ?? "") + "\u{1e}"
            + preferredSorting.rawValue + "\u{1e}"
            + preferredSortOrder.rawValue
    }

    var body: some View {
        ZStack {
            AnimatedGradient(color: .accentColor)
            SelectBookmarkQueryList(
                excludeBookmarkId: excludeBookmarkId,
                trimmedPredicateQuery: trimmedSearch,
                preferredSorting: preferredSorting,
                preferredSortOrder: preferredSortOrder,
                onPick: { id in
                    onPick(id)
                    dismiss()
                }
            )
            .id(queryListIdentity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .searchable(
            text: Binding(
                get: { machine.state.query },
                set: { newValue in
                    Task {
                        await machine.send(.onChangeQuery(newValue))
                    }
                }
            ),
            prompt: Text("Select Bookmark Search Prompt")
        )
        .navigationTitle("Select Bookmark Label")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
        .task {
            await machine.send(.onInit(selectedBookmarkId: nil))
        }
    }
}

// MARK: - Query-backed list

private struct SelectBookmarkQueryList: View {
    @Query
    private var bookmarks: [YabaBookmark]

    let trimmedPredicateQuery: String
    let onPick: (String) -> Void

    init(
        excludeBookmarkId: String?,
        trimmedPredicateQuery: String,
        preferredSorting: SortType,
        preferredSortOrder: SortOrderType,
        onPick: @escaping (String) -> Void
    ) {
        self.trimmedPredicateQuery = trimmedPredicateQuery
        self.onPick = onPick

        let trimmed = trimmedPredicateQuery
        let excludedSelf = excludeBookmarkId ?? ""

        let sortDescriptor: SortDescriptor<YabaBookmark> = switch preferredSorting {
        case .createdAt:
                .init(\.createdAt, order: preferredSortOrder == .ascending ? .forward : .reverse)
        case .editedAt:
                .init(\.editedAt, order: preferredSortOrder == .ascending ? .forward : .reverse)
        case .label:
                .init(\.label, order: preferredSortOrder == .ascending ? .forward : .reverse)
        }

        _bookmarks = Query(
            filter: #Predicate<YabaBookmark> { bookmark in
                (excludedSelf.isEmpty || bookmark.bookmarkId != excludedSelf)
                    && (
                        trimmed.isEmpty
                            || bookmark.label.localizedStandardContains(trimmed)
                            || bookmark.bookmarkDescription?.localizedStandardContains(trimmed) == true
                    )
            },
            sort: [sortDescriptor],
            animation: .smooth
        )
    }

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(bookmarks) { bookmark in
                        Button {
                            onPick(bookmark.bookmarkId)
                        } label: {
                            PresentableBookmarkListRowContent(bookmark: bookmark, showsDisclosureChevron: false)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                    }
                }
                .listRowSpacing(0)
                .scrollContentBackground(.hidden)
                .listStyle(.sidebar)
                #if !os(visionOS)
                .scrollDismissesKeyboard(.immediately)
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var trimmedForCopy: String { trimmedPredicateQuery }

    @ViewBuilder
    private var emptyStateView: some View {
        if trimmedForCopy.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("No Bookmarks Title")
                } icon: {
                    YabaIconView(bundleKey: "bookmark-02")
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                }
            } description: {
                Text("No Bookmarks Message")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView {
                Label {
                    Text("Search No Bookmarks Found Title")
                } icon: {
                    YabaIconView(bundleKey: "bookmark-off-02")
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                }
            } description: {
                Text(
                    LocalizedStringKey(
                        "Search No Bookmarks Found Description \(trimmedForCopy)"
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
