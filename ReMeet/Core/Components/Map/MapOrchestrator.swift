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
    // MARK: - Dependencies
    let profileStore: ProfileStore

    // MARK: - Core Modules
    let mapController = MapController()
    let locationController: MyLocationController
    let friendManager = FriendLocationManager()

    // MARK: - Friend Annotations Cache
    private var annotationCache: [String: UIView] = [:]

    init(profileStore: ProfileStore) {
        self.profileStore = profileStore
        self.locationController = MyLocationController(profileStore: profileStore)

        Task.detached(priority: .background) {
            await self.friendManager.fetchInitialFriends()
            await self.renderInitialFriendPins()
        }

        friendManager.listenForLiveUpdates { [weak self] userId, coordinate in
            Task { @MainActor in
                self?.handleFriendLocationUpdate(userId: userId, coordinate: coordinate)
            }
        }

        Task {
            await self.renderInitialFriendPins()
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

                if let urlStr = friend.photo_url, let url = URL(string: urlStr) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        image = UIImage(data: data)
                    } catch {
                        print("⚠️ Failed to load friend photo: \(error)")
                    }
                }

                let pin = UserPinData(
                    id: friend.friend_id,
                    name: friend.first_name,
                    photoURL: friend.photo_url,
                    coordinate: coordinate
                )

                await MainActor.run {
                    if let rendered = MapAvatarRenderer.render(
                        on: mapView,
                        user: pin,
                        image: image,
                        target: self,
                        tapAction: #selector(self.handleTap(_:))
                    ) {
                        self.annotationCache[userId] = rendered
                    }
                }
            }
        }
    }

    func renderInitialFriendPins() async {
        for (id, friend) in self.friendManager.friends {
            guard let lat = friend.latitude, let lng = friend.longitude else { continue }
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            await MainActor.run {
                self.handleFriendLocationUpdate(userId: id, coordinate: coord)
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
            userInfo: ["friend": friend]
        )

        let coordinate = CLLocationCoordinate2D(latitude: friend.latitude ?? 0, longitude: friend.longitude ?? 0)
        mapController.mapView.camera.ease(
            to: CameraOptions(center: coordinate, zoom: 17),
            duration: 1.0,
            curve: .easeInOut
        )
    }
}
