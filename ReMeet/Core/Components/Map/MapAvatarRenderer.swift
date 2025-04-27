//
//  MapAvatarRenderer.swift
//  ReMeet
//
//  Created by Artush on 23/04/2025.
//

import UIKit
import MapboxMaps

struct UserPinData {
    let id: String
    let name: String
    let photoURL: String?
    let coordinate: CLLocationCoordinate2D
}

final class MapAvatarRenderer {
    static func render(
        on mapView: MapView,
        user: UserPinData,
        image: UIImage?,
        target: Any,
        tapAction: Selector
    ) -> UIView? {
        let initials = String(user.name.prefix(1)).uppercased()

        let annotationView = AnnotationFactory.makeAnnotationView(
            initials: initials,
            image: image,
            userId: user.id,
            target: target,
            action: tapAction
        )

        let options = ViewAnnotationOptions(
            geometry: Point(user.coordinate),
            width: 50,
            height: 50,
            allowOverlap: true,
            anchor: .bottom
        )

        do {
            try mapView.viewAnnotations.add(annotationView, options: options)
            return annotationView
        } catch {
            print("❌ Failed to render avatar for \(user.id): \(error)")
            return nil
        }
    }


    static func update(
        on mapView: MapView,
        view: UIView,
        newCoordinate: CLLocationCoordinate2D
    ) {
        let options = ViewAnnotationOptions(geometry: Point(newCoordinate))
        try? mapView.viewAnnotations.update(view, options: options)
    }
}
