//
//  BottomTabBar.swift
//  ReMeet
//
//  Created by Artush on 08/04/2025.
//

import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: TabBarItem

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
                        .foregroundColor(.black) // or use pink for selected if you prefer
                }

                Spacer()
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 22)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }
}
