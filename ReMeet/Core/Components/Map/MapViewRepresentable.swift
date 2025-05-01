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
                    let isGhostMode = UserDefaults.standard.bool(forKey: "isGhostMode")

                    let ghostImage = UIImage(
                        systemName: "ghost.fill",
                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
                    )?.withTintColor(.gray, renderingMode: .alwaysOriginal)

                    let profileImage = await MainActor.run { orchestrator.profileStore.userImage }

                    let fallbackImage = UIImage(
                        systemName: "person.circle",
                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
                    )?.withTintColor(.gray, renderingMode: .alwaysOriginal)

                    let image: UIImage = isGhostMode
                        ? ghostImage ?? fallbackImage!
                        : profileImage ?? fallbackImage!

                    

                    let initials = await MainActor.run {
                        orchestrator.profileStore.firstName?.prefix(1).uppercased()
                    }
                    let userId = try await SupabaseManager.shared.client.auth.session.user.id.uuidString

                    DispatchQueue.main.async {
                        /*let annotationView = AnnotationFactory.makeAnnotationView(
                            initials: initials,
                            image: image,
                            userId: userId,
                            target: self,
                            action: #selector(self.handleAnnotationTap(_:))
                        )*/
                        
                        let annotationView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
                        annotationView.layer.cornerRadius = 25
                        annotationView.clipsToBounds = true
                        annotationView.backgroundColor = UIColor.systemGray6

                        if isGhostMode {
                            let emojiLabel = UILabel()
                            emojiLabel.text = "👻"
                            emojiLabel.font = UIFont.systemFont(ofSize: 28)
                            emojiLabel.textAlignment = .center
                            emojiLabel.frame = CGRect(x: 0, y: 0, width: annotationView.bounds.width, height: annotationView.bounds.height)
                            emojiLabel.clipsToBounds = true

                            annotationView.addSubview(emojiLabel)
                        } else {
                            // 👤 Profile image view
                            let imageView = UIImageView(image: image)
                            imageView.frame = annotationView.bounds
                            imageView.contentMode = .scaleAspectFill
                            imageView.clipsToBounds = true
                            annotationView.addSubview(imageView)
                        }


                        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleAnnotationTap(_:)))
                        annotationView.addGestureRecognizer(tap)


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
                            print("✅ Annotation view added")
                            self.currentUserAnnotation = annotationView
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
