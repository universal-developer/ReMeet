//
//   MapController.swift
//  ReMeet
//
//  Created by Artush on 16/04/2025.
//

//
//   MapController.swift
//  ReMeet
//
//  Created by Artush on 16/04/2025.
//

import Foundation
import MapboxMaps
import UIKit
import Supabase

@MainActor
class MapController: ObservableObject {
    @Published var userInitials: String? = nil
    @Published var userFirstName: String? = nil
    @Published var friendProfiles: [String: Friend] = [:]
    
    private var lastSavedZoom: CGFloat?

    var userImage: UIImage? = nil

    private static func readLastKnownUserLocation() -> CLLocationCoordinate2D? {
        let lat = UserDefaults.standard.double(forKey: "lastUserLat")
        let lng = UserDefaults.standard.double(forKey: "lastUserLng")
        return lat != 0 && lng != 0 ? CLLocationCoordinate2D(latitude: lat, longitude: lng) : nil
    }

    struct UserPhoto: Decodable {
        let url: String
        let is_main: Bool?
    }

    struct UserProfile: Decodable {
        let first_name: String
    }
    
    struct Friend: Decodable {
        let friend_id: String
        let first_name: String
        let latitude: Double?
        let longitude: Double?
        let photo_url: String?
    }

    let mapView: MapView

    init() {
        let lat = UserDefaults.standard.double(forKey: "lastLat")
        let lng = UserDefaults.standard.double(forKey: "lastLng")
        let zoom = UserDefaults.standard.double(forKey: "lastZoom")
        let adjustedZoom = max(min(zoom - 1.0, 16), 11)
        let userCoord = MapController.readLastKnownUserLocation()

        let initialCamera = userCoord != nil
            ? CameraOptions(center: userCoord, zoom: adjustedZoom)
            : CameraOptions(zoom: 13)

        let mapInitOptions = MapInitOptions(
            cameraOptions: initialCamera,
            styleURI: .streets
        )

        self.mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)

        self.mapView.ornaments.options.scaleBar.visibility = .hidden
        self.mapView.ornaments.options.compass.visibility = .hidden
        self.mapView.location.options.puckType = nil
        self.mapView.location.options.puckBearingEnabled = true

        loadUserData()

        mapView.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            guard let self = self else { return }
            self.saveLastCameraPosition(self.mapView)
        }
    }

    func saveLastCameraPosition(_ mapView: MapView) {
        let center = mapView.mapboxMap.cameraState.center
        let zoom = mapView.mapboxMap.cameraState.zoom

        UserDefaults.standard.set(center.latitude, forKey: "lastLat")
        UserDefaults.standard.set(center.longitude, forKey: "lastLng")
        UserDefaults.standard.set(zoom, forKey: "lastZoom")

        print("📍 Saved camera: lat \(center.latitude), lng \(center.longitude), zoom \(zoom)")

        if abs((lastSavedZoom ?? zoom) - zoom) < 0.1 {
            return
        }

        lastSavedZoom = zoom
        UserDefaults.standard.set(zoom, forKey: "lastZoom")
    }

    func loadUserData() {
        Task {
            async let photo: Void = fetchUserPhoto()
            async let initials: Void = fetchUserProfileInitials()
            _ = await (photo, initials)
        }
    }

    func loadUserDataEagerly() {
        Task.detached(priority: .background) {
            async let photo: Void = self.fetchUserPhoto()
            async let initials: Void = self.fetchUserProfileInitials()
            _ = await (photo, initials)
        }
    }

    func fetchUserProfileInitials() async {
        if let cachedInitial = UserDefaults.standard.string(forKey: "cachedInitials") {
            DispatchQueue.main.async {
                self.userInitials = cachedInitial
            }
        }

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString

                let profiles: [UserProfile] = try await SupabaseManager.shared.client
                    .database
                    .from("profiles")
                    .select("first_name")
                    .eq("id", value: userId)
                    .limit(1)
                    .execute()
                    .value

                guard let profile = profiles.first else {
                    print("⚠️ No profile found.")
                    return
                }

                DispatchQueue.main.async {
                    let initials = String(profile.first_name.prefix(1)).uppercased()
                    self.userInitials = initials
                    self.userFirstName = profile.first_name
                    UserDefaults.standard.set(initials, forKey: "cachedInitials")
                    print("🟣 Initials set to: \(initials)")
                }

            } catch {
                print("❌ Failed to fetch profile initials: \(error)")
            }
        }
    }

    func fetchUserPhoto() async {
        if self.userImage != nil {
            print("🛑 Skipping fetch — image already loaded")
            return
        }

        if let cachedUrlStr = UserDefaults.standard.string(forKey: "cachedPhotoUrl"),
           let url = URL(string: cachedUrlStr) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.userImage = img
                        print("🖼️ Loaded cached user photo")
                    }
                    return
                }
            } catch {
                print("⚠️ Failed to load cached image: \(error)")
            }
        }

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString

                let photos: [UserPhoto] = try await SupabaseManager.shared.client
                    .database
                    .from("user_photos")
                    .select("url, is_main")
                    .eq("user_id", value: userId)
                    .order("is_main", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value

                guard let photoUrl = photos.first?.url,
                      let url = URL(string: photoUrl) else {
                    print("📷 No valid user photo found.")
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    print("❌ Couldn't decode image data")
                    return
                }

                DispatchQueue.main.async {
                    self.userImage = image
                    UserDefaults.standard.set(photoUrl, forKey: "cachedPhotoUrl")
                    print("✅ Loaded user photo")
                }
            } catch {
                print("❌ Error fetching photo from Supabase: \(error)")
            }
        }
    }

    func fetchFriends() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString

            let friends: [Friend] = try await SupabaseManager.shared.client
                .database
                .from("friends_with_metadata")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
                .value

            for friend in friends {
                guard let lat = friend.latitude, let lng = friend.longitude else { continue }
                self.friendProfiles[friend.friend_id] = friend
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                await addFriendAnnotation(friendId: friend.friend_id, firstName: friend.first_name, photoURL: friend.photo_url, coordinate: coordinate)
            }

        } catch {
            print("❌ Failed to fetch friends: \(error)")
        }
    }


    func fetchFriendsAndShowOnMap() async {
        await fetchFriends()
    }
    
    func addFriendAnnotation(friendId: String, firstName: String, photoURL: String?, coordinate: CLLocationCoordinate2D) async {
        DispatchQueue.main.async {
            var image: UIImage? = nil

            if let urlStr = photoURL,
               let url = URL(string: urlStr),
               let data = try? Data(contentsOf: url),
               let decoded = UIImage(data: data) {
                image = decoded
            }

            let annotationView = AnnotationFactory.makeAnnotationView(
                initials: String(firstName.prefix(1)).uppercased(),
                image: image,
                userId: friendId,
                target: self,
                action: #selector(self.friendAnnotationTapped(_:))
            )

            let options = ViewAnnotationOptions(
                geometry: Point(coordinate),
                width: 50,
                height: 50,
                allowOverlap: true,
                anchor: .bottom
            )

            do {
                try self.mapView.viewAnnotations.add(annotationView, options: options)
            } catch {
                print("❌ Error adding friend annotation: \(error)")
            }
        }
    }
    
    @objc func friendAnnotationTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let friendId = view.accessibilityIdentifier else { return }

        if let friend = friendProfiles[friendId] {
            NotificationCenter.default.post(
                name: .didTapUserAnnotation,
                object: nil,
                userInfo: [
                    "userId": friendId,
                    "firstName": friend.first_name,
                    "photoURL": friend.photo_url ?? ""
                ]
            )
        }
    }




    func recenterOnUser() {
        guard let coordinate = mapView.location.latestLocation?.coordinate else {
            print("⚠️ No location available to recenter.")
            return
        }

        let currentZoom = mapView.mapboxMap.cameraState.zoom
        let targetZoom = max(currentZoom, 15)

        mapView.camera.ease(
            to: CameraOptions(center: coordinate),
            duration: 0.8,
            curve: .easeOut
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.mapView.camera.ease(
                to: CameraOptions(center: coordinate, zoom: targetZoom),
                duration: 0.9,
                curve: .easeInOut
            )
        }

        print("🎯 Recentered to user first, then zoomed to \(targetZoom)")
    }

    func zoomInOnUser(_ coordinate: CLLocationCoordinate2D, zoomLevel: CGFloat = 17) {
        let options = CameraOptions(center: coordinate, zoom: zoomLevel)
        mapView.camera.ease(to: options, duration: 1.0, curve: .easeInOut, completion: nil)
    }
}

extension Notification.Name {
    static let didLoadFriendMetadata = Notification.Name("didLoadFriendMetadata")
}
