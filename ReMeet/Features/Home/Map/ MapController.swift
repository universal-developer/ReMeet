//
//   MapController.swift
//  ReMeet
//
//  Created by Artush on 16/04/2025.
//

import Foundation
import MapboxMaps

class MapController: ObservableObject {
    let mapView: MapView

    init() {
        let mapInitOptions = MapInitOptions(
            cameraOptions: CameraOptions(zoom: 14),
            styleURI: .streets
        )

        self.mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)

        // Configure user location dot
        mapView.location.options.puckType = .puck2D()
        mapView.location.options.puckBearingEnabled = true
    }
}


