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
        
        mapView.location.options.puckType = nil

        context.coordinator.mapView = mapView
        context.coordinator.observeUserImageUpdates(controller: controller)

        // Center map when it's loaded
        context.coordinator.mapLoadObserver = mapView.mapboxMap.onMapLoaded.observeNext { _ in
            context.coordinator.mapIsReady = true

            if let coordinate = mapView.location.latestLocation?.coordinate {
                context.coordinator.centerAndAnnotate(
                    coordinate: coordinate,
                    controller: controller
                )
            }
        }

        // Listen for live location updates
        context.coordinator.locationObserver = mapView.location.onLocationChange.observe { locations in
            guard let latest = locations.last else { return }
            context.coordinator.lastLocation = latest.coordinate

            if !context.coordinator.hasCenteredOnUser, context.coordinator.mapIsReady {
                context.coordinator.centerAndAnnotate(
                    coordinate: latest.coordinate,
                    controller: controller
                )
                context.coordinator.hasCenteredOnUser = true
            }
        }

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        // Not used
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var mapView: MapView?
        var hasCenteredOnUser = false
        var mapIsReady = false
        var initialized = false
        var lastLocation: CLLocationCoordinate2D?

        var locationObserver: Cancelable?
        var mapLoadObserver: Cancelable?
        
        @objc func handleAnnotationTap() {
            Task {
                do {
                    let session = try await SupabaseManager.shared.client.auth.session
                    let userId = session.user.id.uuidString
                    
                    NotificationCenter.default.post(
                        name: .didTapUserAnnotation,
                        object: nil,
                        userInfo: ["userId": userId]
                    )
                } catch {
                    print("❌ Failed to get session: \(error)")
                }
            }
        }

        func centerAndAnnotate(coordinate: CLLocationCoordinate2D, controller: MapController) {
            guard let mapView else { return }

            let camera = CameraOptions(center: coordinate, zoom: 15)

            mapView.camera.fly(to: camera, duration: 1.5, completion: nil)


            mapView.viewAnnotations.removeAll()

            let annotationView: UIView

            if let image = controller.userImage {
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
                label.text = controller.userInitials?.uppercased() ?? "?"
                label.textAlignment = .center
                label.textColor = .white
                label.font = .boldSystemFont(ofSize: 22)
                label.backgroundColor = .systemBlue
                label.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
                label.layer.cornerRadius = 25
                label.layer.borderWidth = 2
                label.layer.borderColor = UIColor.white.cgColor
                label.clipsToBounds = true
                annotationView = label
            }

            annotationView.alpha = 0
            annotationView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            annotationView.layer.shadowColor = UIColor.black.cgColor
            annotationView.layer.shadowOpacity = 0.2
            annotationView.layer.shadowOffset = CGSize(width: 0, height: 4)
            annotationView.layer.shadowRadius = 6


            let options = ViewAnnotationOptions(
                geometry: Point(coordinate),
                width: 50,
                height: 50,
                allowOverlap: true,
                anchor: .bottom
            )
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleAnnotationTap))
            annotationView.addGestureRecognizer(tap)
            annotationView.isUserInteractionEnabled = true
            
            do {
                try mapView.viewAnnotations.add(annotationView, options: options)

                let isLowPowerDevice = ProcessInfo.processInfo.isLowPowerModeEnabled
                let duration = isLowPowerDevice ? 0.3 : 0.6

                UIView.animate(
                    withDuration: duration,
                    delay: 0.1,
                    usingSpringWithDamping: 0.7,
                    initialSpringVelocity: 0.8,
                    options: [.curveEaseInOut],
                    animations: {
                        annotationView.alpha = 1
                        annotationView.transform = .identity
                    },
                    completion: nil
                )


            } catch {
                print("❌ Failed to add view annotation: \(error)")
            }

        }

        func observeUserImageUpdates(controller: MapController) {
            NotificationCenter.default.addObserver(forName: .didUpdateUserImage, object: nil, queue: .main) { [weak self] _ in
                guard let self,
                      let mapView = self.mapView,
                      let coordinate = mapView.location.latestLocation?.coordinate else { return }

                self.centerAndAnnotate(coordinate: coordinate, controller: controller)
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

extension Notification.Name {
    static let didUpdateUserImage = Notification.Name("didUpdateUserImage")
}

extension Notification.Name {
    static let didTapUserAnnotation = Notification.Name("didTapUserAnnotation")
}
