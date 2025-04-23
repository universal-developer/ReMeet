//
//  FriendLocationManager.swift
//  ReMeet
//
//  Created by Artush on 23/04/2025.
//

import Foundation
import CoreLocation
import Supabase
import MapboxMaps

final class FriendLocationManager: ObservableObject {
    @Published var friends: [String: Friend] = [:]  // friend_id -> Friend
    private var realtimeChannel: Supabase.RealtimeChannelV2?

    struct Friend: Decodable {
        let friend_id: String
        let first_name: String
        let latitude: Double?
        let longitude: Double?
        let photo_url: String?
    }

    func fetchInitialFriends() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString

            let result: [Friend] = try await SupabaseManager.shared.client
                .from("friends_with_metadata")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
                .value

            DispatchQueue.main.async {
                for friend in result {
                    self.friends[friend.friend_id] = friend
                }
            }
        } catch {
            print("❌ Failed to fetch initial friends: \(error)")
        }
    }

    func listenForLiveUpdates(onUpdate: @escaping (String, CLLocationCoordinate2D) -> Void) {
        let channel = SupabaseManager.shared.client.realtimeV2.channel("public:user_locations")
        let updates = channel.postgresChange(UpdateAction.self, table: "user_locations")

        Task {
            await channel.subscribe()
            for await update in updates {
                let record = update.record
                if let userId = record["user_id"] as? String,
                   let lat = record["latitude"] as? Double,
                   let lng = record["longitude"] as? Double {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    DispatchQueue.main.async {
                        onUpdate(userId, coordinate)
                    }
                } else {
                    print("⚠️ Invalid payload format: \(record)")
                }
            }
        }

        // ✅ FIXED: RealtimeChannelV2 type match
        realtimeChannel = channel
    }


    deinit {
        Task { [weak self] in
            try? await self?.realtimeChannel?.unsubscribe()
            print("🧹 Friend realtime unsubscribed")
        }
    }
}
