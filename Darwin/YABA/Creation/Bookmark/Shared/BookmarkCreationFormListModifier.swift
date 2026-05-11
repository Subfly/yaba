//
//  BookmarkCreationFormListModifier.swift
//  YABA
//

import SwiftUI

struct BookmarkCreationFormListModifier: ViewModifier {
    let mainTint: Color
    /// Docmark trio applies keyboard dismiss on visionOS too; link/note/media omit it there.
    let keyboardDismissBehavior: KeyboardDismissBehavior

    enum KeyboardDismissBehavior {
        case always
        case omitOnVisionOS
    }

    func body(content: Content) -> some View {
        let styled = catalystListStyled(content)
            .scrollContentBackground(.hidden)
            .tint(mainTint)

        #if os(visionOS)
        switch keyboardDismissBehavior {
        case .always:
            styled.scrollDismissesKeyboard(.immediately)
        case .omitOnVisionOS:
            styled
        }
        #else
        styled.scrollDismissesKeyboard(.immediately)
        #endif
    }

    @ViewBuilder
    private func catalystListStyled(_ content: Content) -> some View {
        content.listStyle(.insetGrouped)
    }
}

extension View {
    func bookmarkCreationFormListModifiers(
        mainTint: Color,
        keyboardDismissBehavior: BookmarkCreationFormListModifier.KeyboardDismissBehavior = .omitOnVisionOS
    ) -> some View {
        modifier(
            BookmarkCreationFormListModifier(
                mainTint: mainTint,
                keyboardDismissBehavior: keyboardDismissBehavior
            )
        )
    }
}
