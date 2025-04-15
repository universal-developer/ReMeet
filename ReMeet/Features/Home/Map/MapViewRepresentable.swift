//
//  MapViewRepresentable.swift
//  ReMeet
//
//  Created by Artush on 14/04/2025.
//

import SwiftUI
import MapboxMaps

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var controller: MapController

    func makeUIView(context: Context) -> MapView {
        let mapView = controller.mapView

        if context.coordinator.initialized == false {
            context.coordinator.mapView = mapView

            // Observers only once
            context.coordinator.locationObserver = mapView.location.onLocationChange.observe { locations in
                guard let latest = locations.last else { return }
                if context.coordinator.hasCenteredOnUser == false,
                   context.coordinator.mapIsReady {
                    let camera = CameraOptions(center: latest.coordinate, zoom: 15)
                    mapView.camera.ease(to: camera, duration: 1.3)
                    context.coordinator.hasCenteredOnUser = true
                }
            }

            context.coordinator.mapLoadObserver = mapView.mapboxMap.onMapLoaded.observeNext { _ in
                context.coordinator.mapIsReady = true

                if context.coordinator.hasCenteredOnUser == false,
                   let latest = mapView.location.latestLocation {
                    let camera = CameraOptions(center: latest.coordinate, zoom: 15)
                    mapView.camera.ease(to: camera, duration: 1.0)
                    context.coordinator.hasCenteredOnUser = true
                }
            }

            context.coordinator.initialized = true
        }

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var mapView: MapView?
        var hasCenteredOnUser = false
        var mapIsReady = false
        var initialized = false

        var locationObserver: Cancelable?
        var mapLoadObserver: Cancelable?
    }
}
