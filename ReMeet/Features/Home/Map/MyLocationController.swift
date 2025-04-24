//
//  MyLocationController.swift
//  ReMeet
//
//  Created by Artush on 23/04/2025.
//

import Foundation
import CoreLocation
import Supabase
import MapboxMaps
import UIKit

final class MyLocationController: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var lastUploadTime: TimeInterval = 0

    @Published var userImage: UIImage? = nil
    @Published var initials: String? = nil
    @Published var firstName: String? = nil

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        fetchUserProfileInitials()
        fetchUserPhoto()
    }

    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        uploadLocation(latest.coordinate)
    }

    private func uploadLocation(_ coordinate: CLLocationCoordinate2D) {
        let now = Date().timeIntervalSince1970
        if now - lastUploadTime < 10 { return }
        lastUploadTime = now

        Task.detached(priority: .background) {
            await self.safeUpload(coordinate)
        }
    }

    @Sendable
    private func safeUpload(_ coordinate: CLLocationCoordinate2D) async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString

            struct UploadPayload: Codable {
                let user_id: String
                let latitude: Double
                let longitude: Double
                let updated_at: String
            }

            let payload = UploadPayload(
                user_id: userId,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )

            try await SupabaseManager.shared.client
                .from("user_locations")
                .upsert(payload, returning: .minimal)
                .execute()


            print("✅ Uploaded live location: \(coordinate.latitude), \(coordinate.longitude)")
        } catch {
            print("❌ Location upload failed: \(error)")
        }
    }

    private func fetchUserProfileInitials() {
        if let cached = UserDefaults.standard.string(forKey: "cachedInitials") {
            self.initials = cached
            return
        }

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString

                let profiles: [UserProfile] = try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("first_name")
                    .eq("id", value: userId)
                    .limit(1)
                    .execute()
                    .value

                guard let profile = profiles.first else { return }
                let initial = String(profile.first_name.prefix(1)).uppercased()
                DispatchQueue.main.async {
                    self.initials = initial
                    self.firstName = profile.first_name
                    UserDefaults.standard.set(initial, forKey: "cachedInitials")
                }
            } catch {
                print("❌ Fetch initials failed: \(error)")
            }
        }
    }

    private func fetchUserPhoto() {
        if let cachedUrlStr = UserDefaults.standard.string(forKey: "cachedPhotoUrl"),
           let url = URL(string: cachedUrlStr) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.userImage = image
                        }
                    }
                } catch {
                    print("⚠️ Failed to load cached photo: \(error)")
                }
            }
        }
    }

    struct UserProfile: Decodable {
        let first_name: String
    }
}
