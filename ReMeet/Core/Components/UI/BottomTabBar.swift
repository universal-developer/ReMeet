//
//  BottomTabBar.swift
//  ReMeet
//
//  Created by Artush on 08/04/2025.
//

import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: TabBarItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarItem.allCases, id: \.self) { item in
                Spacer()

                Button(action: {
                    selectedTab = item
                }) {
                    Image(selectedTab == item ? item.filledIconName : item.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(iconColor(for: item))
                }

                Spacer()
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 22)
        .background(
            colorScheme == .dark
            ? Color.black.ignoresSafeArea(edges: .bottom)
            : Color.white.ignoresSafeArea(edges: .bottom)
        )
    }

    private func iconColor(for item: TabBarItem) -> Color {
        if selectedTab == item {
            return colorScheme == .dark ? .white : .black // ✅ selected = white/black
        } else {
            return colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5) // ✅ unselected = faded
        }
    }
}
