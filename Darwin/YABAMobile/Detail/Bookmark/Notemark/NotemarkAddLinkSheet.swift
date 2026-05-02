//
//  NotemarkAddLinkSheet.swift
//  YABA
//

import SwiftUI

enum NotemarkAddLinkSheetMode: Hashable, Sendable {
    case link
    case image
}

struct NotemarkAddLinkSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: NotemarkAddLinkSheetMode

    @State
    private var linkText = ""

    @State
    private var linkUrl = ""

    let onSubmit: (String, String) -> Void

    init(
        mode: NotemarkAddLinkSheetMode = .link,
        onSubmit: @escaping (String, String) -> Void
    ) {
        self.mode = mode
        self.onSubmit = onSubmit
    }

    var body: some View {
        List {
            TextField(firstFieldTitleKey, text: $linkText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Bookmark URL Placeholder", text: $linkUrl)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
        }
        .listStyle(.sidebar)
        .navigationTitle(navigationTitleKey)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onSubmit(trimmedLinkText, trimmedLinkUrl)
                    dismiss()
                }
                .disabled(!canSubmit)
            }
        }.presentationDetents([.fraction(0.3)])
    }

    private var navigationTitleKey: LocalizedStringKey {
        switch mode {
        case .link:
            "Add Link Label"
        case .image:
            "Add Image Link Label"
        }
    }

    private var firstFieldTitleKey: LocalizedStringKey {
        switch mode {
        case .link:
            "Add Link Text To Display Label"
        case .image:
            "Add Image Alt Text Label"
        }
    }

    private var trimmedLinkText: String {
        linkText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLinkUrl: String {
        linkUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        switch mode {
        case .link:
            !trimmedLinkText.isEmpty && !trimmedLinkUrl.isEmpty
        case .image:
            !trimmedLinkUrl.isEmpty
        }
    }
}
