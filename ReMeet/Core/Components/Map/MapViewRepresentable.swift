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
    @ObservedObject var orchestrator: MapOrchestrator

    func makeUIView(context: Context) -> MapView {
        let mapView = orchestrator.mapController.mapView
        mapView.location.options.puckType = nil
        context.coordinator.mapView = mapView

        context.coordinator.mapLoadObserver = mapView.mapboxMap.onMapLoaded.observeNext { _ in
            context.coordinator.mapIsReady = true
            context.coordinator.tryZoomInIfReady(controller: orchestrator.mapController)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .mapDidBecomeVisible, object: nil)
            }
        }

        context.coordinator.locationObserver = mapView.location.onLocationChange.observe { (locations: [Location]) in
            guard let latest = locations.last else { return }
            let coord = latest.coordinate
            context.coordinator.lastCoordinate = coord
            context.coordinator.userLocationReady = true
            context.coordinator.tryZoomInIfReady(controller: orchestrator.mapController)
        }

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(orchestrator: orchestrator)
    }
    
    

    class Coordinator {
        var mapView: MapView?
        var mapIsReady = false
        var userLocationReady = false
        var lastCoordinate: CLLocationCoordinate2D?
        var locationObserver: Cancelable?
        var mapLoadObserver: Cancelable?
        
        private var currentUserAnnotation: UIView?
        private let orchestrator: MapOrchestrator

        init(orchestrator: MapOrchestrator) {
            self.orchestrator = orchestrator
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleZoomOnUser(_:)), name: .zoomOnUser, object: nil)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateCurrentUserAnnotation),
                name: .shouldUpdateUserAnnotation,
                object: nil
            )

        }

        @objc func handleZoomOnUser(_ notification: Notification) {
            guard let coord = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D else { return }
            mapView?.camera.ease(to: CameraOptions(center: coord, zoom: 17), duration: 1.0, curve: .easeInOut)
        }
        
        @objc func updateCurrentUserAnnotation() {
            guard let coordinate = lastCoordinate else { return }
            centerAndAnnotate(coordinate: coordinate, controller: orchestrator.mapController)
        }

        
        @objc func handleAnnotationTap(_ sender: UITapGestureRecognizer) {
            guard let tappedView = sender.view,
                  let userId = tappedView.accessibilityIdentifier,
                  let coordinate = lastCoordinate else { return }

            mapView?.camera.ease(
                to: CameraOptions(center: coordinate, zoom: 17),
                duration: 0.9,
                curve: .easeInOut,
                completion: nil
            )

            NotificationCenter.default.post(
                name: .didTapUserAnnotation,
                object: nil,
                userInfo: ["userId": userId]
            )
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
            
            self.centerAndAnnotate(coordinate: coordinate, controller: controller)
        }
        
        
        
        func centerAndAnnotate(coordinate: CLLocationCoordinate2D, controller: MapController) {
            guard let mapView = mapView else { return }

            // Remove old if exists
            if let existing = self.currentUserAnnotation {
                mapView.viewAnnotations.remove(existing)
            }

            Task { [weak self] in
                guard let self = self else { return }

                do {
                    let image = await MainActor.run { orchestrator.profileStore.userImage }
                    let initials = await MainActor.run {
                        orchestrator.profileStore.firstName?.prefix(1).uppercased()
                    }
                    let userId = try await SupabaseManager.shared.client.auth.session.user.id.uuidString

                    DispatchQueue.main.async {
                        let annotationView = AnnotationFactory.makeAnnotationView(
                            initials: initials,
                            image: image,
                            userId: userId,
                            target: self,
                            action: #selector(self.handleAnnotationTap(_:))
                        )
                        annotationView.accessibilityIdentifier = "currentUser"

                        let options = ViewAnnotationOptions(
                            geometry: Point(coordinate),
                            width: 50,
                            height: 50,
                            allowOverlap: true,
                            anchor: .bottom
                        )

                        do {
                            try mapView.viewAnnotations.add(annotationView, options: options)
                            self.currentUserAnnotation = annotationView // <- ✅ track it!
                            NotificationCenter.default.post(name: .mapDidBecomeVisible, object: nil)
                        } catch {
                            print("❌ Failed to add annotation: \(error)")
                        }
                    }
                } catch {
                    print("❌ Failed to get user ID or user image/initials: \(error)")
                }
            }
        }
        
        


        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
