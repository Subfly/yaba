//
//  BookmarkRouteSelectionContent.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import SwiftUI

struct BookmarkRouteSelectionContent: View {
    let onCancel: () -> Void
    let onSelectKind: (BookmarkKind, MediaMarkType?, DocmarkType?) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradient(color: .blue)
                List {
                    Section {
                        linkRow
                        noteRow
                    } header: {
                        sectionHeaderLabel(
                            title: "Bookmark Route Selection Essentials",
                            iconKey: "bookmark-02"
                        )
                    }
                    Section {
                        routeButton(
                            title: "Bookmark Route Selection New Image",
                            iconKey: "image-03",
                            color: .green,
                            action: { onSelectKind(.media, .image, nil) }
                        )
                        routeButton(
                            title: "Bookmark Route Selection New Audio",
                            iconKey: "audio-wave-01",
                            color: .cyan,
                            action: { onSelectKind(.media, .audio, nil) }
                        )
                        routeButton(
                            title: "Bookmark Route Selection New Video",
                            iconKey: "video-01",
                            color: .indigo,
                            action: { onSelectKind(.media, .video, nil) }
                        )
                    } header: {
                        sectionHeaderLabel(
                            title: "Bookmark Route Selection Media",
                            iconKey: "play-circle"
                        )
                    }
                    Section {
                        routeButton(
                            title: "Bookmark Route Selection New PDF",
                            iconKey: "pdf-02",
                            color: .red,
                            action: { onSelectKind(.file, nil, .pdf) }
                        )
                        routeButton(
                            title: "Bookmark Route Selection New EPUB",
                            iconKey: "book-bookmark-02",
                            color: .orange,
                            action: { onSelectKind(.file, nil, .epub) }
                        )
                        routeButton(
                            title: "Bookmark Route Selection New CSV",
                            iconKey: "csv-02",
                            color: .green,
                            action: { onSelectKind(.file, nil, .csv) }
                        )
                    } header: {
                        sectionHeaderLabel(
                            title: "Bookmark Route Selection Document",
                            iconKey: "doc-02"
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.immediately)
                .scrollContentBackground(.hidden)
                .navigationTitle("New Bookmark")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel, action: onCancel) {
                            Text("Cancel")
                        }
                    }
                }
            }
        }
    }

    private var linkRow: some View {
        routeButton(
            title: "Bookmark Route Selection New Link",
            iconKey: "link-02",
            color: .blue,
            action: { onSelectKind(.link, nil, nil) }
        )
    }

    private var noteRow: some View {
        routeButton(
            title: "Bookmark Route Selection New Note",
            iconKey: "note-edit",
            color: .yellow,
            action: { onSelectKind(.note, nil, nil) }
        )
    }

    @ViewBuilder
    private func sectionHeaderLabel(title: LocalizedStringKey, iconKey: String) -> some View {
        Label {
            Text(title)
        } icon: {
            YabaIconView(bundleKey: iconKey)
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }

    @ViewBuilder
    private func routeButton(
        title: LocalizedStringKey,
        iconKey: String,
        color: YabaColor,
        action: @escaping () -> Void,
        isEnabled: Bool = true
    ) -> some View {
        Button(action: action) {
            HStack {
                YabaIconView(bundleKey: iconKey)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(color.getUIColor())
                    .padding(.trailing, 12)
                Text(title)
                Spacer()
                YabaIconView(bundleKey: "arrow-right-01")
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.secondary)
            }.contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}
