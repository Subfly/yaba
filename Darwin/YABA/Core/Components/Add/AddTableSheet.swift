//
//  AddTableSheet.swift
//  YABA
//

import SwiftUI

struct AddTableSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    @State
    private var rowCount = 3

    @State
    private var columnCount = 3

    let onSubmit: (Int, Int) -> Void

    var body: some View {
        List {
            Stepper(value: $rowCount, in: Self.minDimension ... Self.maxDimension) {
                Text("Table Rows Label \(rowCount)")
            }
            Stepper(value: $columnCount, in: Self.minDimension ... Self.maxDimension) {
                Text("Table Columns Label \(columnCount)")
            }
        }
        #if !targetEnvironment(macCatalyst)
        .listStyle(.sidebar)
        #endif
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
        .presentationDetents([.fraction(0.3)])
    }

    private static let minDimension = 2
    private static let maxDimension = 10
}
