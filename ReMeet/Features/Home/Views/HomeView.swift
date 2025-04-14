//
//  HomeView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
import CoreLocation

struct HomeMapScreen: View {
    let center = CLLocationCoordinate2D(latitude: 39.5, longitude: -98.0)

    var body: some View {
        ZStack {
            MapViewRepresentable()
                .ignoresSafeArea()

            VStack {
                HStack {
                    // Search field (or just an icon if you want a full screen search)
                    Button(action: {
                        print("🔍 Search tapped")
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }

                    Spacer()

                    // Notification button
                    Button(action: {
                        print("🔔 Notifications tapped")
                    }) {
                        Image(systemName: "bell.fill")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60) // adjust for notch

                Spacer()
            }
        }
    }
}

#Preview {
    HomeMapScreen()
}
