//
//  MainAppView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
  
struct MainAppView: View {
    @State private var selectedTab: TabBarItem = .qr
    var orchestrator: MapOrchestrator


    var body: some View {
        VStack(spacing: 0) {
            // Main screen content
            ZStack {
                switch selectedTab {
                case .home:
                    HomeMapScreen(orchestrator: orchestrator)
                case .explore:
                    ExploreView()
                case .qr:
                    QRTabScreen()
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
                _ = orchestrator.mapController.mapView
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

/*#Preview {
    MainAppView(mapController: MapController())
}*/
