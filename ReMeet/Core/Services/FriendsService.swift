//
//  FriendsService.swift
//  ReMeet
//
//  Created by Artush on 19/07/2025.
//

import UIKit

struct FriendsService {
    static func fetchFriends(myId: String) async -> [MinimalUser] {
        do {
            let results = try await SupabaseManager.shared.client
                .from("friends_with_metadata")
                .select("id, first_name, photo_url")
                .eq("user_id", value: myId)
                .execute()

            guard let raw = try? JSONSerialization.jsonObject(with: results.data) as? [[String: Any]] else {
                return []
            }

            var users: [MinimalUser] = []

            for entry in raw {
                guard let id = entry["id"] as? String,
                      let firstName = entry["first_name"] as? String else { continue }

                let urlStr = entry["photo_url"] as? String
                let image = await ImageFetcher.loadAndCacheImage(from: urlStr ?? "")
                users.append(MinimalUser(id: id, firstName: firstName, image: image))
            }

            return users
        } catch {
            print("❌ Failed to fetch friends: \(error)")
            return []
        }
    }

    static func confirmFriendAdd(myId: String, friendId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("friends")
                .insert(["user_id": myId, "friend_id": friendId])
                .execute()

            let url = URL(string: "https://qquleedmyqrpznddhsbv.functions.supabase.co/mirror_friendship")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["user_id": myId, "friend_id": friendId])

            _ = try await URLSession.shared.data(for: request)
        } catch {
            print("❌ Failed to confirm friend add: \(error)")
        }
    }
}

