//
//  ProfileStore.swift
//  ReMeet
//
//  Updated for optimized caching and Supabase sort_order support
//

import Foundation
import SwiftUI

@MainActor
final class ProfileStore: ObservableObject {
    struct UserProfile: Decodable {
        let first_name: String
        let age: Int
    }

    struct UserPhoto: Decodable {
        let url: String
    }

    struct MinimalUser: Identifiable {
        let id: String
        let firstName: String
        let image: UIImage?
    }

    struct ReorderedUserPhoto: Codable {
        let user_id: UUID
        let url: String
        let is_main: Bool
        let sort_order: Int
    }

    static let shared = ProfileStore()

    @Published var userId: String?
    @Published var firstName: String?
    @Published var age: Int?
    @Published var profilePhotoUrl: String?
    @Published var userImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profilePhotoURLs: [String] = []
    @Published var hasLoadedOnce = false

    @AppStorage("profileLastRefreshed") private var lastRefreshedTime: Double = 0

    var lastRefreshed: Date? {
        get { lastRefreshedTime > 0 ? Date(timeIntervalSince1970: lastRefreshedTime) : nil }
        set { lastRefreshedTime = newValue?.timeIntervalSince1970 ?? 0 }
    }

    func loadEverything() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            self.userId = userId

            let profiles: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("first_name, age")
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            await MainActor.run {
                self.firstName = profiles.first?.first_name
                self.age = profiles.first?.age
            }

            let mainPhoto: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId)
                .eq("is_main", value: true)
                .limit(1)
                .execute()
                .value

            if let urlStr = mainPhoto.first?.url {
                await fetchAndCacheMainImage(from: urlStr)
            }

            let allPhotos: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId)
                .order("sort_order", ascending: true)
                .execute()
                .value

            await MainActor.run {
                self.profilePhotoURLs = allPhotos.map { $0.url }
                self.isLoading = false
                self.hasLoadedOnce = true
                self.lastRefreshed = Date()
            }



        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("❌ Failed to load profile: \(error)")
            }
        }
    }

    func refreshUserPhotoFromNetwork() async {
        guard let userId = userId else { return }
        if let last = lastRefreshed, Date().timeIntervalSince(last) < 60 {
            print("⏳ Skipped refresh, too soon")
            return
        }
        lastRefreshed = Date()

        do {
            let mainPhoto: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId)
                .eq("is_main", value: true)
                .limit(1)
                .execute()
                .value

            if let urlStr = mainPhoto.first?.url {
                await fetchAndCacheMainImage(from: urlStr)
                print("🌐 Live photo fetched and updated")
            }
        } catch {
            print("❌ Failed to refresh main photo from network: \(error)")
        }
    }

    func setMainImageAndPush(_ image: UIImage, url: String) async {
        guard let userID = userId else { return }

        do {
            let photo = SupabaseUserPhoto(
                user_id: UUID(uuidString: userID)!,
                url: url,
                is_main: true,
                sort_order: 0
            )
            try await SupabaseManager.shared.client
                .from("user_photos")
                .upsert(photo, onConflict: "user_id,url")
                .execute()

            let key = "user_photo_main"
            await cacheAndBroadcastMainImage(image, from: key)

        } catch {
            print("❌ Failed to push main image: \(error)")
        }
    }

    func syncReorderedPhotos(_ images: [ImageItem]) async {
        guard let userID = userId, let uuid = UUID(uuidString: userID) else { return }

        do {
            // Reset all photos' is_main to false
            try await SupabaseManager.shared.client
                .from("user_photos")
                .update(["is_main": false])
                .eq("user_id", value: userID)
                .execute()

            // Upsert each photo with updated sort_order and is_main
            for (index, item) in images.enumerated() {
                guard let url = item.url else { continue }

                let photo = ReorderedUserPhoto(
                    user_id: uuid,
                    url: url,
                    is_main: index == 0,
                    sort_order: index
                )

                try await SupabaseManager.shared.client
                    .from("user_photos")
                    .upsert(photo, onConflict: "user_id,url")
                    .execute()
            }

            // Update main image
            if let mainItem = images.first, let urlStr = mainItem.url {
                await fetchAndCacheMainImage(from: urlStr)

                if let uiImage = images.first?.image {
                    await MainActor.run {
                        self.userImage = uiImage // ✨ Set immediately
                    }
                }

                NotificationCenter.default.post(name: .didUpdateMainProfilePhoto, object: nil)
            }


            print("✅ Reordered photos synced with is_main + sort_order")
        } catch {
            print("❌ Failed to sync reordered photos: \(error)")
        }
    }

    private func fetchAndCacheMainImage(from urlStr: String) async {
        guard let url = URL(string: urlStr) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await cacheAndBroadcastMainImage(image, from: "user_photo_main")
            }
        } catch {
            print("❌ Failed to download image: \(error)")
        }
    }

    private func cacheAndBroadcastMainImage(_ image: UIImage, from key: String) async {
        ImageCacheManager.shared.setToRAM(image, forKey: key)
        ImageCacheManager.shared.saveToDisk(image, forKey: key)
        await MainActor.run {
            self.userImage = image
        }
        NotificationCenter.default.post(name: .didUpdateMainProfilePhoto, object: nil)
    }

    func loadBasicProfile() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            self.userId = session.user.id.uuidString

            let profiles: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("first_name, age")
                .eq("id", value: userId!)
                .limit(1)
                .execute()
                .value

            await MainActor.run {
                self.firstName = profiles.first?.first_name
                self.age = profiles.first?.age
            }
        } catch {
            print("❌ Basic profile load failed: \(error)")
        }
    }

    func fetchMinimalUser(userId: String) async -> MinimalUser? {
        do {
            let profileData = try await SupabaseManager.shared.client
                .from("profiles")
                .select("first_name")
                .eq("id", value: userId)
                .limit(1)
                .execute()


            var name = "New Friend"
            if let array = try? JSONSerialization.jsonObject(with: profileData.data) as? [[String: Any]],
               let first = array.first,
               let parsedName = first["first_name"] as? String {
                name = parsedName
            }

            var image: UIImage? = nil
            let photoResult = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId)
                .eq("is_main", value: true)
                .limit(1)
                .execute()

            if let array = try? JSONSerialization.jsonObject(with: photoResult.data) as? [[String: Any]],
               let first = array.first,
               let urlString = first["url"] as? String,
               let url = URL(string: urlString) {
                let (data, _) = try await URLSession.shared.data(from: url)
                image = UIImage(data: data)
            }

            return MinimalUser(id: userId, firstName: name, image: image)
        } catch {
            print("❌ Failed to fetch user: \(error)")
            return nil
        }
    }

    func confirmFriendAdd(myId: String, friendId: String) async throws {
        try await SupabaseManager.shared.client
            .from("friends")
            .insert(["user_id": myId, "friend_id": friendId])
            .execute()

        let mirrorURL = URL(string: "https://qquleedmyqrpznddhsbv.functions.supabase.co/mirror_friendship")!
        var request = URLRequest(url: mirrorURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: String] = ["user_id": myId, "friend_id": friendId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        _ = try await URLSession.shared.data(for: request)
    }

    func shouldReloadProfile() -> Bool {
        guard let last = lastRefreshed else { return true }
        return Date().timeIntervalSince(last) > 300
    }

    func loadCachedOrFetchUserPhoto() {
        if let cached = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
            self.userImage = cached
        } else {
            Task {
                await self.refreshUserPhotoFromNetwork()
            }
        }
    }
    
    func loadProfileImagesGrid() async -> [ImageItem] {
        var items: [ImageItem] = []

        for (index, urlStr) in self.profilePhotoURLs.enumerated() {
            guard let url = URL(string: urlStr) else { continue }
            let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: urlStr))"

            if let ram = ImageCacheManager.shared.getFromRAM(forKey: key) {
                items.append(ImageItem(image: ram, isMain: index == 0, url: urlStr))
                continue
            }

            if let disk = ImageCacheManager.shared.loadFromDisk(forKey: key) {
                ImageCacheManager.shared.setToRAM(disk, forKey: key)
                items.append(ImageItem(image: disk, isMain: index == 0, url: urlStr))
                continue
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    ImageCacheManager.shared.setToRAM(image, forKey: key)
                    ImageCacheManager.shared.saveToDisk(image, forKey: key)
                    items.append(ImageItem(image: image, isMain: index == 0, url: urlStr))
                }
            } catch {
                print("❌ Couldn’t fetch image from \(urlStr): \(error)")
            }
        }

        return items
    }

}
