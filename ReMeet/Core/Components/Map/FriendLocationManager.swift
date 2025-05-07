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
    private var ghostRefreshTimer: Timer?
    var onRefetch: ((String, CLLocationCoordinate2D) -> Void)?

    struct Friend: Decodable {
        let friend_id: String
        let first_name: String
        let latitude: Double?
        let longitude: Double?
        let photo_url: String?
        let is_ghost: Bool?
    }
    
    func fetchInitialFriends() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString

            let result: [Friend] = try await SupabaseManager.shared.client
                .from("friends_with_metadata")
                .select("*")
                .eq("user_id", value: userId)
                .eq("is_ghost", value: false)
                .execute()
                .value
            

            DispatchQueue.main.async {
                for friend in result {
                    self.friends[friend.friend_id] = friend
                    let coordinate = CLLocationCoordinate2D(latitude: friend.latitude ?? 0, longitude: friend.longitude ?? 0)
                    self.onRefetch?(friend.friend_id, coordinate) // ← new hook
                }
            }
        } catch {
            print("❌ Failed to fetch initial friends: \(error)")
        }
    }
    
    func listenForLiveUpdates(
        onUpdate: @escaping (String, CLLocationCoordinate2D) -> Void,
        onGhost: @escaping (String) -> Void
    ) {
        Task {
            let channel = await SupabaseManager.shared.client.realtimeV2.channel("user-locations-channel")
            let updates = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "user_locations"
            )
            await channel.subscribe()

            for await update in updates {
                let record = update.record

                guard
                    let userIdRaw = record["user_id"],
                    let ghostRaw = record["is_ghost"],
                    case let .string(userId) = userIdRaw,
                    case let .bool(isGhost) = ghostRaw
                else {
                    print("⚠️ Invalid record: \(record)")
                    continue
                }

                if isGhost {
                    await MainActor.run {
                        self.friends.removeValue(forKey: userId)
                        onGhost(userId)
                        print("📥 Realtime update received for: \(userId), is_ghost=\(record["is_ghost"])")
                    }
                    continue
                }

                guard
                    let latRaw = record["latitude"],
                    let lngRaw = record["longitude"],
                    case let .double(lat) = latRaw,
                    case let .double(lng) = lngRaw
                else {
                    print("⚠️ No valid location provided")
                    continue
                }

                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                DispatchQueue.main.async {
                    onUpdate(userId, coord)
                }
            }

            self.realtimeChannel = channel
        }
    }


    
    func startGhostRefreshTimer(interval: TimeInterval = 30) {
        ghostRefreshTimer?.invalidate()
        ghostRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchInitialFriends()
            }
        }
    }
    
    func stopGhostRefreshTimer() {
        ghostRefreshTimer?.invalidate()
        ghostRefreshTimer = nil
    }




    deinit {
        Task { [weak self] in
            try? await self?.realtimeChannel?.unsubscribe()
            print("🧹 Friend realtime unsubscribed")
        }
    }
}
