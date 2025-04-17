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

            if let coordinate = mapView.location.latestLocation?.coordinate {
                context.coordinator.centerAndAnnotate(
                    coordinate: coordinate,
                    controller: controller,
                    userId: userId
                )
            }
        }

        context.coordinator.locationObserver = mapView.location.onLocationChange.observe { locations in
            guard let latest = locations.last else { return }

            if !context.coordinator.hasCenteredOnUser, context.coordinator.mapIsReady {
                context.coordinator.centerAndAnnotate(
                    coordinate: latest.coordinate,
                    controller: controller,
                    userId: userId
                )
                context.coordinator.hasCenteredOnUser = true
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

        func centerAndAnnotate(coordinate: CLLocationCoordinate2D, controller: MapController, userId: String) {
            guard let mapView = mapView else { return }

            mapView.camera.fly(to: CameraOptions(center: coordinate, zoom: 15), duration: 1.2)

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
                label.text = controller.userInitials ?? "?"
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
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleAnnotationTap(_:)))
            annotationView.addGestureRecognizer(tap)

            let options = ViewAnnotationOptions(
                geometry: Point(coordinate),
                width: 50,
                height: 50,
                allowOverlap: true,
                anchor: .bottom
            )

            do {
                try mapView.viewAnnotations.add(annotationView, options: options)
            } catch {
                print("❌ Failed to add annotation: \(error)")
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
