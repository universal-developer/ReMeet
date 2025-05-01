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
    struct LocationPayload: Codable {
        let user_id: String
        let latitude: Double // <- match your real column name
        let longitude: Double
        let is_ghost: Bool
    }
    
    private let locationManager = CLLocationManager()
    private var lastUploadTime: TimeInterval = 0

    @Published var userImage: UIImage? = nil
    @Published var initials: String? = nil
    @Published var firstName: String? = nil
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined

    private let profileStore: ProfileStore
    var onProfileLoaded: () -> Void = {}

    init(profileStore: ProfileStore, onProfileLoaded: @escaping () -> Void) {
        self.profileStore = profileStore
        self.onProfileLoaded = onProfileLoaded
        super.init()
        locationManager.delegate = self
        requestPermissions()
        locationManager.startUpdatingLocation()
        loadFromProfileStore()
        permissionStatus = locationManager.authorizationStatus
    }

    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        uploadUserLocation(latest)

    }

    func uploadUserLocation(_ location: CLLocation) {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString

                let isGhost = UserDefaults.standard.bool(forKey: "isGhostMode")

                let payload = LocationPayload(
                    user_id: userId,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    is_ghost: isGhost
                )

                try await SupabaseManager.shared.client
                    .from("user_locations")
                    .upsert(payload, returning: .minimal)
                    .execute()


                print("📡 Location uploaded: ghost=\(isGhost)")
            } catch {
                print("❌ Upload failed: \(error)")
            }
        }
    }



    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionStatus = manager.authorizationStatus
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

    private func loadFromProfileStore() {
        Task { @MainActor in
            self.firstName = profileStore.firstName
            self.initials = profileStore.firstName?.prefix(1).uppercased()
            self.userImage = profileStore.userImage
            onProfileLoaded() // Notify orchestrator directly
        }
    }
}
