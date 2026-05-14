//
//  AddLinkSheet.swift
//  YABA
//

import SwiftUI

enum AddLinkSheetMode: Hashable, Sendable {
    case link
    case image
}

struct AddLinkSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: AddLinkSheetMode

    let accentColor: Color

    @State
    private var linkText = ""

    @State
    private var linkUrl = ""

    let onSubmit: (String, String) -> Void

    init(
        mode: AddLinkSheetMode = .link,
        accentColor: Color = .accentColor,
        onSubmit: @escaping (String, String) -> Void
    ) {
        self.mode = mode
        self.accentColor = accentColor
        self.onSubmit = onSubmit
    }

    /// Larger sheet / window chrome on iPad
    private var isPadIdiom: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var presentationHeightDetent: PresentationDetent {
        .fraction(isPadIdiom ? 0.36 : 0.25)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradient(color: accentColor)
                List {
                    TextField(firstFieldTitleKey, text: $linkText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Bookmark URL Placeholder", text: $linkUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
            }
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
            }
        }
        #if !targetEnvironment(macCatalyst)
        .presentationDragIndicator(.visible)
        #else
        .frame(width: 600, height: 260)
        .presentationSizing(.fitted)
        #endif
        .presentationDetents([presentationHeightDetent])
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
