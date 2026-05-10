//
//  BookmarkCreationFormSections.swift
//  YABA
//

import SwiftUI

// MARK: - Info section chrome

enum BookmarkCreationInfoSectionHeaderBuilders {
    @ViewBuilder
    static func infoTitleAndIcon() -> some View {
        Label {
            Text("Info")
        } icon: {
            YabaIconView(bundleKey: "information-circle")
                .frame(width: 22, height: 22)
        }
    }

    /// Standard creation “Info” section header (`Info` leading, optional trailing accessory).
    @ViewBuilder
    static func infoHeader() -> some View {
        infoHeaderAccessory { EmptyView() }
    }

    @ViewBuilder
    static func infoHeaderAccessory<Accessory: View>(
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            infoTitleAndIcon()
            Spacer(minLength: 0)
            accessory()
        }
    }
}

// MARK: - Title / description / pin

struct BookmarkCreationPinnedTitleDescriptionFields: View {
    let mainTint: Color
    @Binding var label: String
    @Binding var bookmarkDescription: String
    @Binding var isPinned: Bool
    let pinIconBundleKey: String

    var body: some View {
        TextField(
            "",
            text: $label,
            prompt: Text("Create Bookmark Title Placeholder")
        )
        .safeAreaInset(edge: .leading) {
            BookmarkCreationLeadingFieldIcon(bundleKey: "text", mainTint: mainTint)
        }
        TextField(
            "",
            text: $bookmarkDescription,
            prompt: Text("Create Bookmark Description Placeholder"),
            axis: .vertical
        )
        .lineLimit(3 ... 8)
        .safeAreaInset(edge: .leading) {
            BookmarkCreationLeadingFieldIcon(bundleKey: "paragraph", mainTint: mainTint)
        }
        Toggle(isOn: $isPinned) {
            Label {
                Text("Bookmark Creation Toggle Pinned Title")
            } icon: {
                BookmarkCreationLeadingFieldIcon(bundleKey: pinIconBundleKey, mainTint: mainTint)
                    .animation(.smooth, value: isPinned)
            }
        }
    }
}

// MARK: - Last-error row

/// Shared red error snippet used across bookmark creation forms.
struct BookmarkCreationLastErrorSection: View {
    let message: String?

    var body: some View {
        if let message {
            Section {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }
}
