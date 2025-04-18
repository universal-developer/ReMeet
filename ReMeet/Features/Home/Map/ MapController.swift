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
    private var lastSavedZoom: CGFloat?

    var userImage: UIImage? = nil
    var lastKnownUserLocation: CLLocationCoordinate2D? {
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

    let mapView: MapView

    init() {
        // Load last saved camera if available
        let lat = UserDefaults.standard.double(forKey: "lastLat")
        let lng = UserDefaults.standard.double(forKey: "lastLng")
        let zoom = UserDefaults.standard.double(forKey: "lastZoom")

        let hasValidCoords = lat != 0 && lng != 0 && zoom != 0

        let adjustedZoom = max(min(zoom - 1.0, 16), 11)

        let lastUserLat = UserDefaults.standard.double(forKey: "lastUserLat")
        let lastUserLng = UserDefaults.standard.double(forKey: "lastUserLng")
        let hasLastUserCoord = lastUserLat != 0 && lastUserLng != 0

        let userCoord = self.lastKnownUserLocation
        let initialCamera = userCoord != nil
            ? CameraOptions(center: userCoord, zoom: adjustedZoom)
            : CameraOptions(zoom: 13)

        let mapInitOptions = MapInitOptions(
            cameraOptions: initialCamera,
            styleURI: .streets
        )
        
        self.mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)

        // UI preferences
        self.mapView.ornaments.options.scaleBar.visibility = .hidden
        self.mapView.ornaments.options.compass.visibility = .hidden
        self.mapView.location.options.puckType = nil
        self.mapView.location.options.puckBearingEnabled = true

        // Start loading user-related data
        loadUserData()

        // Save camera every time it changes
        mapView.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            guard let self = self else { return }
            self.saveLastCameraPosition(self.mapView)
        }

    }

    // MARK: - Save Camera Position

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

    // MARK: - User Data

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
        // First, try local cache
        if let cachedInitial = UserDefaults.standard.string(forKey: "cachedInitials") {
            DispatchQueue.main.async {
                self.userInitials = cachedInitial
            }
        }

        // Then fetch from Supabase
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

        // Try cached image first (async-safe)
        if let cachedUrlStr = UserDefaults.standard.string(forKey: "cachedPhotoUrl"),
           let url = URL(string: cachedUrlStr) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.userImage = img
                        print("🖼️ Loaded cached user photo")
                    }
                    return // don't proceed to Supabase call
                }
            } catch {
                print("⚠️ Failed to load cached image: \(error)")
            }
        }

        // Then fetch latest from Supabase
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
    
    func recenterOnUser() {
        if let coordinate = mapView.location.latestLocation?.coordinate {
            let zoom = UserDefaults.standard.double(forKey: "lastZoom")
            let camera = CameraOptions(center: coordinate, zoom: zoom != 0 ? zoom : 15)
            mapView.camera.ease(to: camera, duration: 1.0, curve: .easeInOut, completion: nil)
            print("🎯 Recentered on user location")
        } else {
            print("⚠️ No location available to recenter.")
        }
    }



}
