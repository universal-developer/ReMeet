//
//   MapController.swift
//  ReMeet
//
//  Created by Artush on 16/04/2025.
//

import Foundation
import MapboxMaps
import CoreLocation
import UIKit

@MainActor
final class MapController: ObservableObject {
    let mapView: MapView
    private var lastSavedZoom: CGFloat?

    init() {
        let lat = UserDefaults.standard.double(forKey: "lastLat")
        let lng = UserDefaults.standard.double(forKey: "lastLng")
        let zoom = UserDefaults.standard.double(forKey: "lastZoom")
        let adjustedZoom = max(min(zoom - 1.0, 16), 11)
        let userCoord = MapController.readLastKnownUserLocation()

        let initialCamera = userCoord != nil
            ? CameraOptions(center: userCoord, zoom: adjustedZoom)
            : CameraOptions(zoom: 13)

        let mapInitOptions = MapInitOptions(
            cameraOptions: initialCamera,
            styleURI: .streets
        )

        self.mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)

        self.mapView.ornaments.options.scaleBar.visibility = .hidden
        self.mapView.ornaments.options.compass.visibility = .hidden
        self.mapView.location.options.puckType = nil
        self.mapView.location.options.puckBearingEnabled = true

        mapView.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            guard let self = self else { return }
            self.saveLastCameraPosition(self.mapView)
        }
    }

    static func readLastKnownUserLocation() -> CLLocationCoordinate2D? {
        let lat = UserDefaults.standard.double(forKey: "lastUserLat")
        let lng = UserDefaults.standard.double(forKey: "lastUserLng")
        return lat != 0 && lng != 0 ? CLLocationCoordinate2D(latitude: lat, longitude: lng) : nil
    }

    func saveLastCameraPosition(_ mapView: MapView) {
        let center = mapView.mapboxMap.cameraState.center
        let zoom = mapView.mapboxMap.cameraState.zoom

        UserDefaults.standard.set(center.latitude, forKey: "lastLat")
        UserDefaults.standard.set(center.longitude, forKey: "lastLng")
        UserDefaults.standard.set(zoom, forKey: "lastZoom")

        print("📍 Saved camera: lat \(center.latitude), lng \(center.longitude), zoom \(zoom)")

        if abs((lastSavedZoom ?? zoom) - zoom) < 0.1 {
            return
        }

        lastSavedZoom = zoom
        UserDefaults.standard.set(zoom, forKey: "lastZoom")
    }

    func zoomInOnUser(_ coordinate: CLLocationCoordinate2D, zoomLevel: CGFloat = 17) {
        let options = CameraOptions(center: coordinate, zoom: zoomLevel)
        mapView.camera.ease(to: options, duration: 1.0, curve: .easeInOut, completion: nil)
    }

    func recenterOnUser() {
        guard let coordinate = mapView.location.latestLocation?.coordinate else {
            print("⚠️ No location available to recenter.")
            return
        }

        let currentZoom = mapView.mapboxMap.cameraState.zoom
        let targetZoom = max(currentZoom, 15)

        mapView.camera.ease(to: CameraOptions(center: coordinate), duration: 0.8, curve: .easeOut)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.mapView.camera.ease(to: CameraOptions(center: coordinate, zoom: targetZoom), duration: 0.9, curve: .easeInOut)
        }

        print("🎯 Recentered to user first, then zoomed to \(targetZoom)")
    }

    func removeAllAnnotations() {
        mapView.viewAnnotations.removeAll()
    }

    func updateAnnotationPosition(for view: UIView, coordinate: CLLocationCoordinate2D) {
        let options = ViewAnnotationOptions(geometry: Point(coordinate))
        try? mapView.viewAnnotations.update(view, options: options)
    }
}
