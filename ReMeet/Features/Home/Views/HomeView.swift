//
//  HomeView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
import MapboxMaps

struct HomeMapScreen: View {
    @ObservedObject var mapController: MapController
    
    @State private var mapViewRef: MapView? = nil
    @State private var showModal = false
    @State private var tappedUserId: String?
    
    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
               MapViewRepresentable(controller: mapController)
                   .ignoresSafeArea()
                   .onReceive(NotificationCenter.default.publisher(for: .didTapUserAnnotation)) { notification in
                       if let userId = notification.userInfo?["userId"] as? String {
                           tappedUserId = userId
                           showModal = true
                       }
                   }
           }
            VStack {
                HStack(spacing: 12) {
                    // Avatar
                    Button(action: {
                        print("👤 Avatar tapped")
                    }) {
                        Image("profilePlaceholder") // Replace with real avatar later
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Search pill
                    Button(action: {
                        print("🔍 Search tapped")
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Earth") // Or user's current area
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }

                    Spacer()

                    // Settings
                    Button(action: {
                        print("⚙️ Settings tapped")
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 30)

                Spacer()
            }
            

        }
        // ✅ Snapchat-style modal preview
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
            if showModal, let userId = tappedUserId {
                FastUserPreviewCard(userId: userId)
                    .padding(.bottom, 6) // Small spacing from very bottom
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showModal)
            }
        }

    }
}

#Preview {
    HomeMapScreen(mapController: MapController())
}
