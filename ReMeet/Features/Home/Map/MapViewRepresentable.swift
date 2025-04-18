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
    let userId: String

    func makeUIView(context: Context) -> MapView {
        let mapView = controller.mapView
        mapView.location.options.puckType = nil
        context.coordinator.mapView = mapView

        context.coordinator.mapLoadObserver = mapView.mapboxMap.onMapLoaded.observeNext { _ in
            context.coordinator.mapIsReady = true
            context.coordinator.tryZoomInIfReady(controller: controller, userId: userId)

            // ⏳ Defer profile fetch slightly after map renders
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                controller.loadUserDataEagerly()
            }
        }

        context.coordinator.locationObserver = mapView.location.onLocationChange.observe { locations in
            guard let latest = locations.last else { return }
            context.coordinator.lastCoordinate = latest.coordinate
            context.coordinator.userLocationReady = true
            context.coordinator.tryZoomInIfReady(controller: controller, userId: userId)
            
            if let coord = locations.last?.coordinate {
                    UserDefaults.standard.set(coord.latitude, forKey: "lastUserLat")
                    UserDefaults.standard.set(coord.longitude, forKey: "lastUserLng")
                }
        }

        return mapView
    }


    func updateUIView(_ uiView: MapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator {
        var mapView: MapView?
        var hasCenteredOnUser = false
        var mapIsReady = false
        var userLocationReady = false
        var lastCoordinate: CLLocationCoordinate2D?
        var locationObserver: Cancelable?
        var mapLoadObserver: Cancelable?
        
        @objc func handleAnnotationTap(_ sender: UITapGestureRecognizer) {
            guard let tappedView = sender.view,
                  let userId = tappedView.accessibilityIdentifier else {
                print("❌ Couldn't find tapped view or user ID.")
                return
            }

            NotificationCenter.default.post(name: .didTapUserAnnotation, object: nil, userInfo: ["userId": userId])
        }
        
        func tryZoomInIfReady(controller: MapController, userId: String) {
            guard mapIsReady, userLocationReady, let coordinate = lastCoordinate else { return }

            // prevent double fire
            mapIsReady = false
            userLocationReady = false

            // Smooth fly-in
            let storedZoom = UserDefaults.standard.double(forKey: "lastZoom")
            let finalZoom = storedZoom != 0 ? storedZoom : 15

            mapView?.camera.fly(to: CameraOptions(center: coordinate, zoom: finalZoom), duration: 1.2)

            // Add annotation right after
            self.centerAndAnnotate(coordinate: coordinate, controller: controller, userId: userId)
            
            UserDefaults.standard.set(coordinate.latitude, forKey: "lastUserLat")
            UserDefaults.standard.set(coordinate.longitude, forKey: "lastUserLng")

        }
        
        func centerAndAnnotate(coordinate: CLLocationCoordinate2D, controller: MapController, userId: String) {
            guard let mapView = mapView else { return }

            let storedZoom = UserDefaults.standard.double(forKey: "lastZoom")
            let shouldZoomIn = storedZoom != 0

            let zoomOutZoom: CGFloat = shouldZoomIn ? storedZoom - 2 : 12
            let targetZoom: CGFloat = shouldZoomIn ? storedZoom : 15

            // Animate in one motion if no zoom-out needed
            if !shouldZoomIn {
                mapView.camera.fly(to: CameraOptions(center: coordinate, zoom: targetZoom), duration: 1.2)
            } else {
                mapView.camera.fly(to: CameraOptions(center: coordinate, zoom: zoomOutZoom), duration: 0.6)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    mapView.camera.fly(to: CameraOptions(center: coordinate, zoom: targetZoom), duration: 1.0)
                }
            }

            // Add annotation
            mapView.viewAnnotations.removeAll()
            
            
            
            Task { [weak self] in
                guard let self = self else { return }

                let image = await MainActor.run { controller.userImage }
                let initials = await MainActor.run { controller.userInitials }

                DispatchQueue.main.async {
                    let annotationView: UIView
                    if let image = image {
                        let imageView = UIImageView(image: image)
                        imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
                        imageView.contentMode = .scaleAspectFill
                        imageView.layer.cornerRadius = 25
                        imageView.layer.borderWidth = 2
                        imageView.layer.borderColor = UIColor.white.cgColor
                        imageView.clipsToBounds = true
                        annotationView = imageView
                    } else {
                        let label = UILabel()
                        label.text = initials ?? "?"
                        label.textColor = .white
                        label.textAlignment = .center
                        label.font = .boldSystemFont(ofSize: 22)
                        label.backgroundColor = .systemBlue
                        label.layer.cornerRadius = 25
                        label.layer.borderWidth = 2
                        label.layer.borderColor = UIColor.white.cgColor
                        label.clipsToBounds = true
                        label.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
                        annotationView = label
                    }

                    annotationView.accessibilityIdentifier = userId
                    annotationView.isUserInteractionEnabled = true
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleAnnotationTap(_:)))
                    annotationView.addGestureRecognizer(tap)

                    let options = ViewAnnotationOptions(
                        geometry: Point(coordinate),
                        width: 50,
                        height: 50,
                        allowOverlap: true,
                        anchor: .bottom
                    )

                    do {
                        try self.mapView?.viewAnnotations.add(annotationView, options: options)
                    } catch {
                        print("❌ Failed to add annotation: \(error)")
                    }
                }
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

extension Notification.Name {
    static let didTapUserAnnotation = Notification.Name("didTapUserAnnotation")
}
