//
//  BookmarkCreationDismiss.swift
//  YABA
//

import SwiftUI

enum BookmarkCreationDismiss {
    static func perform(
        bookmarkCreationOnCloseRequest: (() -> Void)?,
        dismiss: DismissAction
    ) {
        if let bookmarkCreationOnCloseRequest {
            bookmarkCreationOnCloseRequest()
        } else {
            dismiss()
        }
    }
}
