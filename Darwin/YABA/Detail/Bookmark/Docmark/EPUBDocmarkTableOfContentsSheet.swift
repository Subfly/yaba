//
//  EPUBDocmarkTableOfContentsSheet.swift
//  YABA
//
//  Table of contents sheet for EPUB detail (Readium manifest `tableOfContents`).
//

import Observation
import ReadiumNavigator
import ReadiumShared
import SwiftUI

// MARK: - Navigation bridge (toolbar sheet → navigator)

@MainActor
@Observable
final class EPUBDocmarkTOCBridge {
    weak var navigator: EPUBNavigatorViewController?
    private(set) var publication: Publication?

    func setPublication(_ publication: Publication?) {
        self.publication = publication
    }

    func attach(navigator: EPUBNavigatorViewController?) {
        self.navigator = navigator
    }

    @discardableResult
    func go(to link: ReadiumShared.Link) async -> Bool {
        guard let navigator else { return false }
        return await navigator.go(to: link, options: .animated)
    }

    func resetForUnload() {
        navigator = nil
        publication = nil
    }
}

// MARK: - Outline rows (hierarchical List)

struct EPUBDocmarkTOCOutlineRow: Identifiable {
    let id: UUID
    let title: String
    let link: ReadiumShared.Link
    let children: [EPUBDocmarkTOCOutlineRow]?

    var isFolder: Bool { children != nil }

    init(link: ReadiumShared.Link) {
        id = UUID()
        self.link = link
        let trimmed = link.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        title = trimmed.isEmpty ? link.href : trimmed
        if link.children.isEmpty {
            children = nil
        } else {
            children = link.children.map { EPUBDocmarkTOCOutlineRow(link: $0) }
        }
    }
}

// MARK: - List

struct EPUBDocmarkTableOfContentsList: View {
    let rootItems: [EPUBDocmarkTOCOutlineRow]
    let onSelectLink: (ReadiumShared.Link) -> Void

    var body: some View {
        List(rootItems, children: \.children) { item in
            Label {
                Text(item.title)
            } icon: {
                YabaIconView(bundleKey: item.isFolder ? "book-bookmark-02" : "file-02")
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelectLink(item.link)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Sheet chrome

struct EPUBDocmarkTableOfContentsSheet: View {
    let bridge: EPUBDocmarkTOCBridge
    let folderTint: SwiftUI.Color
    var dismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradient(color: folderTint)
                Group {
                    if let publication = bridge.publication {
                        let roots = publication.manifest.tableOfContents.map { EPUBDocmarkTOCOutlineRow(link: $0) }
                        if roots.isEmpty {
                            ContentUnavailableView {
                                Label {
                                    Text("No ToC Title")
                                } icon: {
                                    YabaIconView(bundleKey: "left-to-right-list-triangle")
                                        .scaledToFit()
                                        .frame(width: 52, height: 52)
                                        .foregroundStyle(folderTint)
                                }
                            } description: {
                                Text("No ToC Description")
                            }
                        } else {
                            EPUBDocmarkTableOfContentsList(rootItems: roots, onSelectLink: { link in
                                Task { @MainActor in
                                    _ = await bridge.go(to: link)
                                    dismiss()
                                }
                            })
                        }
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("ToC Navigation Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .tint(folderTint)
        }
    }
}
