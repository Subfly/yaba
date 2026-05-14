//
//  AddTableSheet.swift
//  YABA
//

import SwiftUI

struct AddTableSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    let accentColor: Color

    @State
    private var rowCount = 3

    @State
    private var columnCount = 3

    let onSubmit: (Int, Int) -> Void

    init(
        accentColor: Color = .accentColor,
        onSubmit: @escaping (Int, Int) -> Void
    ) {
        self.accentColor = accentColor
        self.onSubmit = onSubmit
    }

    /// Larger sheet / window chrome on iPad
    private var isPadIdiom: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var presentationHeightDetent: PresentationDetent {
        .fraction(isPadIdiom ? 0.32 : 0.28)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradient(color: accentColor)
                List {
                    Stepper(value: $rowCount, in: Self.minDimension ... Self.maxDimension) {
                        Text("Table Rows Label \(rowCount)")
                    }
                    Stepper(value: $columnCount, in: Self.minDimension ... Self.maxDimension) {
                        Text("Table Columns Label \(columnCount)")
                    }
                }
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Table Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSubmit(rowCount, columnCount)
                        dismiss()
                    }
                }
            }
        }
        #if !targetEnvironment(macCatalyst)
        .presentationDragIndicator(.visible)
        #else
        .frame(width: 600, height: 240)
        .presentationSizing(.fitted)
        #endif
        .presentationDetents([presentationHeightDetent])
    }

    private static let minDimension = 2
    private static let maxDimension = 10
}
