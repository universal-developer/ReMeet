//
//  MainAppView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
  
struct MainAppView: View {
    @State private var selectedTab: TabBarItem = .qr
    @ObservedObject var mapController: MapController

    var body: some View {
        VStack(spacing: 0) {
            // Main screen content
            ZStack {
                switch selectedTab {
                case .home:
                    HomeMapScreen(mapController: mapController)
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
        .onAppear {
            DispatchQueue.global().async {
                _ = mapController.mapView
                mapController.loadUserData()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MainAppView(mapController: MapController())
}
