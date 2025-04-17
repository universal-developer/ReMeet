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

class MapController: ObservableObject {
    @Published var userInitials: String? = nil
    var userImage: UIImage? = nil
    

    struct UserPhoto: Decodable {
        let url: String
        let is_main: Bool?
    }

    struct UserProfile: Decodable {
        let first_name: String
    }

    let mapView: MapView

    init() {
        let mapInitOptions = MapInitOptions(
            cameraOptions: CameraOptions(zoom: 14),
            styleURI: .streets // MUCH faster and more minimal
        )
        self.mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)
        self.mapView.ornaments.options.scaleBar.visibility = .hidden
        self.mapView.ornaments.options.compass.visibility = .hidden
        mapView.location.options.puckType = nil
        mapView.location.options.puckBearingEnabled = true

        // Optionally load on init
        loadUserData()
    }

    func loadUserData() {
        fetchUserPhoto()
        fetchUserProfileInitials()
    }

    func fetchUserProfileInitials() {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString

                let profiles: [MapController.UserProfile] = try await SupabaseManager.shared.client
                    .database
                    .from("profiles")
                    .select("first_name")
                    .eq("id", value: userId)
                    .limit(1)
                    .execute()
                    .value

                guard let profile = profiles.first else { return }


                if let profile = profiles.first {
                    DispatchQueue.main.async {
                        self.userInitials = String(profile.first_name.prefix(1)).uppercased()
                        print("🟣 Initials set to: \(self.userInitials!)")
                    }
                } else {
                    print("⚠️ No profile found for user.")
                }
            } catch {
                print("❌ Failed to fetch profile initials: \(error)")
            }
        }
    }

    func fetchUserPhoto() {
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


                guard let photoUrl = photos.first?.url else {
                    print("📷 No user photo found.")
                    return
                }

                guard let url = URL(string: photoUrl) else {
                    print("❌ Invalid URL: \(photoUrl)")
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    print("❌ Couldn't decode image")
                    return
                }

                DispatchQueue.main.async {
                    self.userImage = image
                    print("✅ Loaded user photo")

                }


            } catch {
                print("❌ Error fetching photo: \(error)")
            }
        }
    }
}


