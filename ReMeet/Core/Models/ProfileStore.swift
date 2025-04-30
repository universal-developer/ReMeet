//
//  ProfileStore.swift
//  ReMeet
//
//  Created by Artush on 01/05/2025.
//

import Foundation
import SwiftUI

@MainActor
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    @Published var userId: String?
    @Published var firstName: String?
    @Published var age: Int?
    @Published var profilePhotoUrl: String?
    @Published var userImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?


    func load() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            userId = session.user.id.uuidString

            let profiles: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("first_name")
                .eq("id", value: userId!)
                .limit(1)
                .execute()
                .value

            firstName = profiles.first?.first_name

            let photos: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId!)
                .eq("is_main", value: true)
                .limit(1)
                .execute()
                .value

            profilePhotoUrl = photos.first?.url

            if let urlStr = profilePhotoUrl, let url = URL(string: urlStr) {
                let (data, _) = try await URLSession.shared.data(from: url)
                userImage = UIImage(data: data)
            }

            print("✅ Profile loaded: \(firstName ?? "?" )")
        } catch {
            print("❌ Failed to load profile: \(error)")
        }
    }

    struct UserProfile: Decodable {
        let first_name: String
    }

    struct UserPhoto: Decodable {
        let url: String
    }
}
