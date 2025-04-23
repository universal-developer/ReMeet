//
//  MapViewRepresentable.swift
//  ReMeet
//
//  Created by Artush on 14/04/2025.
//

import SwiftUI
import MapboxMaps
import MapboxCoreMaps
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var controller: MapController

    func makeUIView(context: Context) -> MapView {
        let mapView = controller.mapView
        mapView.location.options.puckType = nil
        context.coordinator.mapView = mapView

        context.coordinator.mapLoadObserver = mapView.mapboxMap.onMapLoaded.observeNext { _ in
            context.coordinator.mapIsReady = true
            context.coordinator.tryZoomInIfReady(controller: controller)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .mapDidBecomeVisible, object: nil)
            }
        }

        context.coordinator.locationObserver = mapView.location.onLocationChange.observe { (locations: [Location]) in
            guard let latest = locations.last else { return }
            let coord = latest.coordinate
            context.coordinator.lastCoordinate = coord
            context.coordinator.userLocationReady = true
            context.coordinator.tryZoomInIfReady(controller: controller)
        }

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var mapView: MapView?
        var mapIsReady = false
        var userLocationReady = false
        var lastCoordinate: CLLocationCoordinate2D?
        var locationObserver: Cancelable?
        var mapLoadObserver: Cancelable?

        init() {
            NotificationCenter.default.addObserver(self, selector: #selector(handleZoomOnUser(_:)), name: .zoomOnUser, object: nil)
        }

        @objc func handleZoomOnUser(_ notification: Notification) {
            guard let coord = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D else { return }
            mapView?.camera.ease(to: CameraOptions(center: coord, zoom: 17), duration: 1.0, curve: .easeInOut)
        }

        func tryZoomInIfReady(controller: MapController) {
            guard mapIsReady, userLocationReady, let coordinate = lastCoordinate else { return }

            mapIsReady = false
            userLocationReady = false

            let storedZoom = UserDefaults.standard.double(forKey: "lastZoom")
            let finalZoom = storedZoom != 0 ? storedZoom : 15

            mapView?.mapboxMap.setCamera(to: CameraOptions(center: coordinate, zoom: finalZoom))
            UserDefaults.standard.set(coordinate.latitude, forKey: "lastUserLat")
            UserDefaults.standard.set(coordinate.longitude, forKey: "lastUserLng")
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

extension Notification.Name {
    static let mapDidBecomeVisible = Notification.Name("mapDidBecomeVisible")
    static let zoomOnUser = Notification.Name("zoomOnUser")
    static let didTapUserAnnotation = Notification.Name("didTapUserAnnotation")
}
