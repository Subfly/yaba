//
//  CreateContentFAB.swift
//  YABA
//
//  Created by Ali Taha on 8.10.2024.
//

import SwiftUI

struct HomeCreateContentFAB: View {
    @AppStorage(Constants.preferredFabPositionKey)
    private var preferredPosition: FabPosition = .center

    @Namespace private var animation

    @Binding
    var isActive: Bool
    let onClickAction: (_ type: CreationType) -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill()
                .foregroundStyle(Material.ultraThin)
                .blur(radius: 8)
                .opacity(isActive ? 0.6 : 0)
                .onTapGesture {
                    onClickAction(.main)
                }
        }.overlay(
            alignment: preferredPosition == .center
                ? .bottom
                : preferredPosition == .left
                ? .bottomLeading
                : .bottomTrailing
        ) {
            GlassEffectContainer(spacing: 18) {
                VStack(spacing: 16) {
                    if isActive {
                        Button {
                            onClickAction(.bookmark)
                        } label: {
                            fab(isMini: true, type: .bookmark)
                        }
                        .glassEffectTransition(.matchedGeometry)
                        .glassEffectID(4, in: animation)

                        Button {
                            onClickAction(.folder)
                        } label: {
                            fab(isMini: true, type: .folder)
                        }
                        .glassEffectTransition(.matchedGeometry)
                        .glassEffectID(3, in: animation)

                        Button {
                            onClickAction(.tag)
                        } label: {
                            fab(isMini: true, type: .tag)
                        }
                        .glassEffectTransition(.matchedGeometry)
                        .glassEffectID(2, in: animation)
                    }

                    Button {
                        onClickAction(.main)
                    } label: {
                        fab(isMini: false, type: .main)
                    }
                    .glassEffectID(1, in: animation)
                }
                .padding(.bottom)
                .padding(.bottom)
                .padding(.leading, preferredPosition == .left ? 32 : 0)
                .padding(.trailing, preferredPosition == .right ? 32 : 0)
            }.animation(.smooth, value: isActive)
        }
    }

    @ViewBuilder
    private func fab(isMini: Bool, type: CreationType) -> some View {
        Group {
            YabaIconView(bundleKey: type.getIcon())
                .foregroundStyle(.white)
                .frame(
                    width: isMini ? 18 : 24,
                    height: isMini ? 18 : 24
                )
                .rotationEffect(Angle(degrees: isMini ? 0 : isActive ? 45 : 0))
        }
        .frame(
            width: isMini ? 48 : 72,
            height: isMini ? 48 : 72
        )
        .glassEffect(.regular.tint(.accentColor.opacity(0.5)).interactive(), in: .circle)
    }
}

#Preview {
    HomeCreateContentFAB(
        isActive: .constant(true),
        onClickAction: { _ in
            // Do Nothing
        }
    )
}
