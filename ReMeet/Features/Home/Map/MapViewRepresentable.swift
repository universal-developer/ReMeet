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

            
            // Notify HomeMapScreen to fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .mapDidBecomeVisible, object: nil)
            }
            
            // ⏳ Defer profile fetch slightly after map renders
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                controller.loadUserDataEagerly()
            }
            
            // 🧠 🔥 Add this line to load friends on map
            Task {
                await controller.fetchFriendsAndShowOnMap()
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
        
        init() {
            NotificationCenter.default.addObserver(self, selector: #selector(handleZoomOnUser(_:)), name: .zoomOnUser, object: nil)
        }

        
        @objc func handleAnnotationTap(_ sender: UITapGestureRecognizer) {
            guard let tappedView = sender.view,
                  let userId = tappedView.accessibilityIdentifier,
                  let coordinate = lastCoordinate else { return }

            // Zoom in very close (level 17)
            mapView?.camera.ease(
                to: CameraOptions(center: coordinate, zoom: 17),
                duration: 0.9,
                curve: .easeInOut,
                completion: nil
            )

            NotificationCenter.default.post(name: .didTapUserAnnotation, object: nil, userInfo: ["userId": userId])
        }
        
        @objc func friendAnnotationTapped(_ sender: UITapGestureRecognizer) {
            guard let view = sender.view,
                  let friendId = view.accessibilityIdentifier else { return }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFriendMetadata(_:)),
                name: .didLoadFriendMetadata,
                object: nil
            )
        }
        
        @objc func handleFriendMetadata(_ notification: Notification) {
            guard let friends = notification.userInfo?["friends"] as? [MapController.Friend] else { return }

            for friend in friends {
                guard let lat = friend.latitude, let lng = friend.longitude else { continue }
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)

                DispatchQueue.main.async {
                    let annotationView = AnnotationFactory.makeAnnotationView(
                        initials: String(friend.first_name.prefix(1)).uppercased(),
                        image: nil, // preload if needed
                        userId: friend.friend_id,
                        target: self,
                        action: #selector(self.handleAnnotationTap(_:))
                    )

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
                        print("❌ Error adding friend annotation: \(error)")
                    }
                }
            }
        }


        @objc func handleZoomOnUser(_ notification: Notification) {
                guard let coord = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D else { return }
                mapView?.camera.ease(to: CameraOptions(center: coord, zoom: 17), duration: 1.0, curve: .easeInOut, completion: nil)
            }

        
        func tryZoomInIfReady(controller: MapController, userId: String) {
            guard mapIsReady, userLocationReady, let coordinate = lastCoordinate else { return }

            // Prevent double fire
            mapIsReady = false
            userLocationReady = false

            // Get last zoom or fallback
            let storedZoom = UserDefaults.standard.double(forKey: "lastZoom")
            let finalZoom = storedZoom != 0 ? storedZoom : 15

            // Instantly center without animation
            mapView?.mapboxMap.setCamera(to: CameraOptions(center: coordinate, zoom: finalZoom))

            // Save updated user location
            UserDefaults.standard.set(coordinate.latitude, forKey: "lastUserLat")
            UserDefaults.standard.set(coordinate.longitude, forKey: "lastUserLng")

            // Add profile annotation
            self.centerAndAnnotate(coordinate: coordinate, controller: controller, userId: userId)
        }

        
        func centerAndAnnotate(coordinate: CLLocationCoordinate2D, controller: MapController, userId: String) {
            guard let mapView = mapView else { return }

            let storedZoom = UserDefaults.standard.double(forKey: "lastZoom")
            let finalZoom: CGFloat = storedZoom != 0 ? storedZoom : 15

            mapView.viewAnnotations.removeAll()

            Task { [weak self] in
                guard let self = self else { return }

                let image = await MainActor.run { controller.userImage }
                let initials = await MainActor.run { controller.userInitials }

                DispatchQueue.main.async {
                    let annotationView = AnnotationFactory.makeAnnotationView(
                        initials: initials,
                        image: image,
                        userId: userId,
                        target: self,
                        action: #selector(self.handleAnnotationTap(_:))
                    )

                    let options = ViewAnnotationOptions(
                        geometry: Point(coordinate),
                        width: 50,
                        height: 50,
                        allowOverlap: true,
                        anchor: .bottom
                    )

                    do {
                        try mapView.viewAnnotations.add(annotationView, options: options)
                        NotificationCenter.default.post(name: .mapDidBecomeVisible, object: nil)
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
    static let mapDidBecomeVisible = Notification.Name("mapDidBecomeVisible")
    static let didTapUserAnnotation = Notification.Name("didTapUserAnnotation")
    static let zoomOnUser = Notification.Name("zoomOnUser")
}

