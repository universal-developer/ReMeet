//
//  MapViewRepresentable.swift
//  ReMeet
//
//  Created by Artush on 14/04/2025.
//

import SwiftUI
import MapboxMaps

struct MapViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> MapView {
        let mapInitOptions = MapInitOptions(
            cameraOptions: CameraOptions(zoom: 14),
            styleURI: .streets
        )

        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)

        // Setup blue dot (user location)
        mapView.location.options.puckType = .puck2D()
        mapView.location.options.puckBearingEnabled = true

        // Store mapView in coordinator
        context.coordinator.mapView = mapView

        // Observe location changes
        mapView.location.onLocationChange.observe { locations in
            guard let latest = locations.last else { return }
            let camera = CameraOptions(center: latest.coordinate, zoom: 15)
            mapView.camera.ease(to: camera, duration: 1.3)
        }

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var mapView: MapView?
    }
}
