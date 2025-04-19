//
//  CompassLocationButton.swift
//  ReMeet
//
//  Created by Artush on 20/04/2025.
//

//  CompassLocationButton.swift
//  ReMeet

import SwiftUI
import MapboxMaps

struct CompassLocationButton: View {
    @ObservedObject var mapController: MapController
    @Binding var isCompassActive: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    if isCompassActive {
                        mapController.resetCameraToUser() // ← recenters & resets bearing
                        isCompassActive = false
                    } else {
                        mapController.recenterOnUser()
                    }
                }) {
                    Image(systemName: isCompassActive ? "location.north.line.fill" : "location.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.bottom, 40)
                .padding(.trailing, 16)
            }
        }
    }
}
