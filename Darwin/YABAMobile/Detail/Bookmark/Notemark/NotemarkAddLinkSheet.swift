//
//  NotemarkAddLinkSheet.swift
//  YABA
//

import SwiftUI

struct NotemarkAddLinkSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    @State
    private var linkText = ""

    @State
    private var linkUrl = ""

    let onSubmit: (String, String) -> Void

    var body: some View {
        Form {
            TextField("Add Link Text To Display Label", text: $linkText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Bookmark URL Placeholder", text: $linkUrl)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
        }
        .navigationTitle("Add Link Label")
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

    private var trimmedLinkText: String {
        linkText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLinkUrl: String {
        linkUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedLinkText.isEmpty && !trimmedLinkUrl.isEmpty
    }
}
