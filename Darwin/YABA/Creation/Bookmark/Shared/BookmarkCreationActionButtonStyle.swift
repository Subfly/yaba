//
//  BookmarkCreationActionButtonStyle.swift
//  YABA
//

import SwiftUI

extension View {
    func bookmarkCreationActionButtonLabelStyle(mainTint: Color, isDisabled: Bool) -> some View {
        self
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDisabled ? mainTint.opacity(0.45) : mainTint)
            }
            .foregroundStyle(.white)
    }
}
