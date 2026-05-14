//
//  HowToGuideView.swift
//  YABA
//
//  Created by Ali Taha on 9.09.2025.
//

import SwiftUI

private enum HowToGuidePage: Hashable {
    case keyboard, reminders, tips

    func getTitle() -> LocalizedStringKey {
        switch self {
        case .keyboard: "How To Keyboard Title"
        case .reminders: "How To Reminders Title"
        case .tips: "How To Tips Title"
        }
    }

    func getUIIconName() -> String {
        switch self {
        case .keyboard: "keyboard"
        case .reminders: "notification-01"
        case .tips: "sparkles"
        }
    }

    func getColor() -> Color {
        switch self {
        case .keyboard: .teal
        case .reminders: .yellow
        case .tips: .green
        }
    }
}

struct HowToGuideView: View {
    @Environment(\.dismiss)
    private var dismiss

    @State
    private var path: [HowToGuidePage] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AnimatedGradient(color: .accentColor)
                List {
                    generateHowToItem(for: .keyboard)
                    generateHowToItem(for: .reminders)
                    generateHowToItem(for: .tips)
                }
                #if !targetEnvironment(macCatalyst)
                .listStyle(.sidebar)
                #endif
                .listRowSpacing(12)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings How To Guide Title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .navigationDestination(for: HowToGuidePage.self) { destination in
                switch destination {
                case .keyboard: HowToKeyboard()
                case .reminders: HowToReminders()
                case .tips: HowToTips()
                }
            }
            .presentationDetents([.large])
            #if !targetEnvironment(macCatalyst)
            .presentationDragIndicator(.visible)
            #endif
        }
    }

    @ViewBuilder
    private func generateHowToItem(for page: HowToGuidePage) -> some View {
        NavigationLink(value: page) {
            Label {
                Text(page.getTitle())
            } icon: {
                YabaIconView(bundleKey: page.getUIIconName())
                    .foregroundStyle(page.getColor())
                    .frame(width: 24, height: 24)
            }
        }
    }
}

#Preview {
    HowToGuideView()
}
