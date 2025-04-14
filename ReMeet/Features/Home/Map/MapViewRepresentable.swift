//
//  Map.swift
//  ReMeet
//
//  Created by Artush on 14/04/2025.
//

import SwiftUI
import MapboxMaps
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> MapView {
        let resourceOptions = ResourceOptions(accessToken: Secrets.mapboxToken)
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {}
}
