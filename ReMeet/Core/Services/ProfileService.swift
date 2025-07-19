//
//  ProfileService.swift
//  ReMeet
//
//  Created by Artush on 19/07/2025.
//

import UIKit

struct ProfileService {
    static func getCurrentProfileAndPhotos(userId: String) async throws -> (UserProfile?, [UserPhoto]) {
        let profile: [UserProfile] = try await SupabaseManager.shared.client
            .from("profiles")
            .select("first_name, age")
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value

        let photos: [UserPhoto] = try await SupabaseManager.shared.client
            .from("user_photos")
            .select("url, is_main")
            .eq("user_id", value: userId)
            .order("sort_order", ascending: true)
            .execute()
            .value

        return (profile.first, photos)
    }

    static func fetchMinimalUser(userId: String) async -> MinimalUser? {
        do {
            let profileResult = try await SupabaseManager.shared.client
                .from("profiles")
                .select("first_name")
                .eq("id", value: userId)
                .limit(1)
                .execute()

            let name = try (JSONSerialization.jsonObject(with: profileResult.data) as? [[String: Any]])?
                .first?["first_name"] as? String ?? "New Friend"

            let photoResult = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId)
                .eq("is_main", value: true)
                .limit(1)
                .execute()

            let urlStr = try (JSONSerialization.jsonObject(with: photoResult.data) as? [[String: Any]])?
                .first?["url"] as? String

            let image = await ImageFetcher.loadAndCacheImage(from: urlStr ?? "")

            return MinimalUser(id: userId, firstName: name, image: image)
        } catch {
            print("❌ Failed to fetch minimal user: \(error)")
            return nil
        }
    }
}

