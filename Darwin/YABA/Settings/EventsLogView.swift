//
//  EventsLogView.swift
//  YABA
//
//  Created by Ali Taha on 30.05.2025.
//

import SwiftUI

/// Developer event log UI. Legacy `YabaDataLog` / `YabaDataLogger` models were removed with the v2 parity schema;
/// this screen is kept so Settings navigation compiles and can be wired to a new logger later.
internal struct EventsLogView: View {
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ZStack {
            AnimatedGradient(color: .accentColor)
            List {
                Section {
                    ContentUnavailableView {
                        Label {
                            Text("Settings Event Logs Label")
                        } icon: {
                            YabaIconView(bundleKey: "calendar-03")
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                    } description: {
                        Text(verbatim: "The current data model does not include a persisted change log. This list will show entries when logging is wired to the v2 schema.")
                    }
                }
            }
            #if !targetEnvironment(macCatalyst)
            .listStyle(.sidebar)
            #endif
            .scrollContentBackground(.hidden)
            .background(.clear)
        }
        .navigationTitle("Settings Event Logs Label")
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .pad {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            } else {
                ToolbarItem(placement: .navigation) {
                    Button {
                        dismiss()
                    } label: {
                        YabaIconView(bundleKey: "arrow-left-01")
                    }
                }
            }
        }
    }
}
