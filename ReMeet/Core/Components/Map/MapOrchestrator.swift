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
    private var ghostedFriendIds: Set<String> = []

    init(profileStore: ProfileStore) {
        self.profileStore = profileStore

        self.locationController = MyLocationController(
            profileStore: profileStore,
            onProfileLoaded: { }
        )

        self.locationController.onProfileLoaded = { [weak self] in
            Task { [weak self] in
                guard let self else { return }
                await self.renderCurrentUserPin()
                await self.renderInitialFriendPins()
            }
        }

        NotificationCenter.default.post(name: .shouldUpdateUserAnnotation, object: nil)

        Task.detached(priority: .background) {
            await self.friendManager.fetchInitialFriends()
            await MainActor.run { [weak self] in
                guard let self else { return }
                Task { await self.renderInitialFriendPins() }
            }
        }

        friendManager.listenForLiveUpdates(
            onUpdate: { [weak self] (userId, coordinate) in
                Task { [weak self] in
                    guard let self else { return }
                    await self.handleFriendLocationUpdate(userId: userId, coordinate: coordinate)
                }
            },
            onGhost: { [weak self] userId in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    print("👻 onGhost triggered for: \(userId)")
                    await self.removeZombieAnnotations(for: userId)
                }
            }
        )

        friendManager.onRefetch = { [weak self] userId, coordinate in
            Task { [weak self] in
                guard let self = self,
                      let friend = self.friendManager.friends[userId],
                      friend.is_ghost != true else {
                    return
                }
                await self.handleFriendLocationUpdate(userId: userId, coordinate: coordinate)
            }
        }

        self.startZombieSweeper()
        friendManager.startGhostRefreshTimer(interval: 30)

        NotificationCenter.default.addObserver(forName: .didToggleGhostMode, object: nil, queue: .main) { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                guard let location = await self.locationController.locationManager.location else { return }
                await self.locationController.uploadUserLocation(location)

                for (id, friend) in self.friendManager.friends where friend.is_ghost == true {
                    await self.removeZombieAnnotations(for: id)
                }
            }
        }

        NotificationCenter.default.addObserver(forName: .didExternallyUpdateGhostStatus, object: nil, queue: .main) { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                await self.friendManager.fetchInitialFriends()
                await self.renderInitialFriendPins()
            }
        }
    }

    // MARK: - Render or Update Friend Pins
    func handleFriendLocationUpdate(userId: String, coordinate: CLLocationCoordinate2D) async {
        guard let friend = friendManager.friends[userId], friend.is_ghost != true else {
            await removeZombieAnnotations(for: userId)
            return
        }

        await removeZombieAnnotations(for: userId)

        let mapView = mapController.mapView

        if let cachedView = annotationCache[userId] {
            let isStillVisible = mapView.viewAnnotations.allAnnotations.contains { $0.view == cachedView }
            if isStillVisible {
                print("🛑 Skipping rendering — already exists and visible: \(userId)")
                return
            } else {
                annotationCache.removeValue(forKey: userId)
                print("🧼 Cached annotation stale — removing \(userId)")
            }
        }

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

        if let view = MapAvatarRenderer.render(
            on: mapView,
            user: pin,
            image: image,
            target: self,
            tapAction: #selector(self.handleTap(_:))
        ) {
            view.accessibilityIdentifier = userId
            annotationCache[userId] = view
        }
    }

    // MARK: - Zombie Cleanup
    private func removeZombieAnnotations(for userId: String) async {
        guard let annotationManager = mapController.mapView.viewAnnotations else { return }

        for annotation in annotationManager.allAnnotations {
            let view = annotation.view
            if view.accessibilityIdentifier == userId {
                annotationManager.remove(view)
                annotationCache.removeValue(forKey: userId)
                print("💀 Removed zombie annotation for user: \(userId)")
            }
        }
    }

    private func startZombieSweeper(interval: TimeInterval = 15) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                for (userId, view) in self.annotationCache {
                    let isMissing = self.friendManager.friends[userId] == nil
                    let isGhost = self.friendManager.friends[userId]?.is_ghost == true
                    if isMissing || isGhost {
                        self.mapController.mapView.viewAnnotations?.remove(view)
                        self.annotationCache.removeValue(forKey: userId)
                        print("🧹 Swept zombie annotation: \(userId)")
                    }
                }
            }
        }
    }

    // MARK: - Render User Pin
    func renderCurrentUserPin() async {
        guard let name = profileStore.firstName, !name.isEmpty else { return }

        let mapView = mapController.mapView
        let center = mapView.mapboxMap.cameraState.center

        let pin = UserPinData(
            id: profileStore.userId ?? UUID().uuidString,
            name: name,
            photoURL: nil,
            coordinate: center
        )

        let image = profileStore.userImage

        if let view = MapAvatarRenderer.render(
            on: mapView,
            user: pin,
            image: image,
            target: self,
            tapAction: #selector(self.handleTap(_:))
        ) {
            view.accessibilityIdentifier = pin.id
            annotationCache[pin.id] = view
        }
    }

    func renderInitialFriendPins() async {
        for (id, friend) in friendManager.friends {
            guard let lat = friend.latitude,
                  let lng = friend.longitude,
                  friend.is_ghost == false else { continue }

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            await handleFriendLocationUpdate(userId: id, coordinate: coord)
        }
    }

    // MARK: - Tap Handler
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let friendId = view.accessibilityIdentifier,
              let friend = friendManager.friends[friendId] else { return }

        let isCurrentUser = friend.friend_id == profileStore.userId

        NotificationCenter.default.post(
            name: .didTapUserAnnotation,
            object: nil,
            userInfo: isCurrentUser
                ? ["userId": profileStore.userId ?? "unknown" as Any]
                : ["friend": friend]
        )

        let coordinate = CLLocationCoordinate2D(
            latitude: friend.latitude ?? 0,
            longitude: friend.longitude ?? 0
        )

        mapController.mapView.camera.ease(
            to: CameraOptions(center: coordinate, zoom: 17),
            duration: 1.2,
            curve: .easeInOut
        )
    }
}
