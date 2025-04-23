//
//  MapOrchestrator.swift
//  ReMeet
//
//  Created by Artush on 24/04/2025.
//

import Foundation
import CoreLocation
import MapboxMaps
import SwiftUI

@MainActor
final class MapOrchestrator: ObservableObject {
    // MARK: - Core Modules
    let mapController = MapController()
    let locationController = MyLocationController()
    let friendManager = FriendLocationManager()

    // MARK: - Friend Annotations Cache
    private var annotationCache: [String: UIView] = [:]

    init() {
        Task.detached(priority: .background) {
            await self.friendManager.fetchInitialFriends()
        }

        // Subscribe to live updates of friend positions
        friendManager.listenForLiveUpdates { [weak self] userId, coordinate in
            Task { @MainActor in
                self?.handleFriendLocationUpdate(userId: userId, coordinate: coordinate)
            }
        }
    }

    // MARK: - Render or Update Friend Pins
    private func handleFriendLocationUpdate(userId: String, coordinate: CLLocationCoordinate2D) {
        guard let friend = friendManager.friends[userId] else {
            print("⚠️ Friend not found in cache for id: \(userId)")
            return
        }

        let mapView = mapController.mapView

        if let existing = annotationCache[userId] {
            MapAvatarRenderer.update(on: mapView, view: existing, newCoordinate: coordinate)
        } else {
            Task.detached(priority: .background) {
                var image: UIImage? = nil

                if let urlStr = friend.photo_url, let url = URL(string: urlStr),
                   let data = try? Data(contentsOf: url),
                   let img = UIImage(data: data) {
                    image = img
                }

                let pin = UserPinData(
                    id: friend.friend_id,
                    name: friend.first_name,
                    photoURL: friend.photo_url,
                    coordinate: coordinate
                )

                DispatchQueue.main.async {
                    MapAvatarRenderer.render(
                        on: mapView,
                        user: pin,
                        image: image,
                        target: self,
                        tapAction: #selector(self.handleTap(_:))
                    )
                }
            }
        }
    }

    // MARK: - Tap Handler
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let friendId = view.accessibilityIdentifier,
              let friend = friendManager.friends[friendId] else { return }

        NotificationCenter.default.post(
            name: .didTapUserAnnotation,
            object: nil,
            userInfo: [
                "userId": friend.friend_id,
                "firstName": friend.first_name,
                "photoURL": friend.photo_url ?? ""
            ]
        )
    }
}

