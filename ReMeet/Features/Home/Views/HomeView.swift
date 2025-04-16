//
//  HomeView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
import MapboxMaps

struct HomeMapScreen: View {
    @State private var mapViewRef: MapView? = nil
    @ObservedObject var mapController: MapController
    
    var body: some View {
        ZStack {
            MapViewRepresentable(controller: mapController)
                            .ignoresSafeArea()
                            .edgesIgnoringSafeArea(.all)

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
    }
}

#Preview {
    HomeMapScreen(mapController: MapController())
}
