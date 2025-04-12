//
//  MainAppView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
  
struct MainAppView: View {
    @State private var selectedTab: TabBarItem = .home

    var body: some View {
        VStack(spacing: 0) {
            // Main screen content
            ZStack {
                switch selectedTab {
                case .home:
                    HomeView()
                case .explore:
                    ExploreView()
                case .qr:
                    QRHubView()
                case .messages:
                    MessagesView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom navigation bar
            BottomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MainAppView()
}
