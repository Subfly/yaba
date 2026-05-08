//
//  BookmarkRouteSelectionContent.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import SwiftUI

struct BookmarkRouteSelectionContent: View {
    let onCancel: () -> Void
    let onSelectKind: (BookmarkKind, MediaMarkType?) -> Void

    var body: some View {
        NavigationStack {
            List {
                linkRow
                noteRow
                mediaDisclosureSection
                documentDisclosureSection
            }
            .listStyle(.sidebar)
            #if !os(visionOS)
            .scrollDismissesKeyboard(.immediately)
            #endif
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

    private var linkRow: some View {
        routeButton(
            title: "Bookmark Route Selection New Link",
            iconKey: "link-02",
            color: .blue,
            showsChevron: true,
            action: { onSelectKind(.link, nil) }
        )
    }

    private var noteRow: some View {
        routeButton(
            title: "Bookmark Route Selection New Note",
            iconKey: "note-edit",
            color: .yellow,
            showsChevron: true,
            action: { onSelectKind(.note, nil) }
        )
    }

    private var mediaDisclosureSection: some View {
        DisclosureGroup {
            routeButton(
                title: "Bookmark Route Selection New Image",
                iconKey: "image-03",
                color: .green,
                showsChevron: true,
                action: { onSelectKind(.media, .image) }
            )
            routeButton(
                title: "Bookmark Route Selection New Audio",
                iconKey: "audio-wave-01",
                color: .cyan,
                showsChevron: true,
                action: { onSelectKind(.media, .audio) }
            )
            routeButton(
                title: "Bookmark Route Selection New Video",
                iconKey: "video-01",
                color: .indigo,
                showsChevron: true,
                action: { onSelectKind(.media, .video) }
            )
        } label: {
            disclosureLabel(
                title: "Bookmark Route Selection Media",
                iconKey: "play-circle",
                color: .red
            )
        }
    }

    private var documentDisclosureSection: some View {
        DisclosureGroup {
            routeButton(
                title: "Bookmark Route Selection New PDF",
                iconKey: "pdf-02",
                color: .red,
                showsChevron: true,
                action: { onSelectKind(.file, nil) }
            )
            routeButton(
                title: "Bookmark Route Selection New EPUB",
                iconKey: "book-bookmark-02",
                color: .mint,
                showsChevron: false,
                action: {},
                isEnabled: false
            )
            routeButton(
                title: "Bookmark Route Selection New CSV",
                iconKey: "csv-02",
                color: .green,
                showsChevron: false,
                action: {},
                isEnabled: false
            )
        } label: {
            disclosureLabel(
                title: "Bookmark Route Selection Document",
                iconKey: "doc-02",
                color: .orange
            )
        }
    }

    @ViewBuilder
    private func disclosureLabel(title: LocalizedStringKey, iconKey: String, color: YabaColor) -> some View {
        HStack {
            YabaIconView(bundleKey: iconKey)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(color.getUIColor())
                .padding(.trailing, 12)
            Text(title)
            Spacer()
        }
    }

    @ViewBuilder
    private func routeButton(
        title: LocalizedStringKey,
        iconKey: String,
        color: YabaColor,
        showsChevron: Bool,
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
                if showsChevron {
                    YabaIconView(bundleKey: "arrow-right-01")
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(.secondary)
                }
            }.contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}
