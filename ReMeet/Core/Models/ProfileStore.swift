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
    
    static let shared = ProfileStore()

    @Published var userId: String?
    @Published var firstName: String?
    @Published var age: Int?
    @Published var profilePhotoUrl: String?
    @Published var userImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profilePhotoURLs: [String] = []
    @Published var cachedProfileImages: [ImageItem] = []
    @Published var lastRefreshed: Date? = nil

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

            // Load and cache main photo
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

            // Load all profile photos
            let allPhotos: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId)
                .order("created_at", ascending: true)
                .execute()
                .value

            let urls = allPhotos.map { $0.url }

            await MainActor.run {
                self.profilePhotoURLs = urls
            }

            var imageItems: [ImageItem] = []

            for (i, urlStr) in urls.enumerated() {
                guard let url = URL(string: urlStr) else { continue }
                let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: urlStr))"

                if let ramImage = ImageCacheManager.shared.getFromRAM(forKey: key) {
                    imageItems.append(ImageItem(image: ramImage, isMain: i == 0, url: urlStr))
                    if i == 0 { await cacheAndBroadcastMainImage(ramImage, from: key) }
                    continue
                }

                if let diskImage = ImageCacheManager.shared.loadFromDisk(forKey: key) {
                    ImageCacheManager.shared.setToRAM(diskImage, forKey: key)
                    imageItems.append(ImageItem(image: diskImage, isMain: i == 0, url: urlStr))
                    if i == 0 { await cacheAndBroadcastMainImage(diskImage, from: key) }
                    continue
                }

                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        ImageCacheManager.shared.setToRAM(image, forKey: key)
                        ImageCacheManager.shared.saveToDisk(image, forKey: key)
                        imageItems.append(ImageItem(image: image, isMain: i == 0, url: urlStr))
                        if i == 0 { await cacheAndBroadcastMainImage(image, from: key) }
                    }
                } catch {
                    print("❌ Couldn’t fetch image from \(urlStr): \(error)")
                }
            }

            await MainActor.run {
                self.cachedProfileImages = imageItems
                self.isLoading = false
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
                is_main: true
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
            for (index, item) in images.enumerated() {
                guard let url = item.url else { continue }

                let photo = SupabaseUserPhoto(
                    user_id: uuid,
                    url: url,
                    is_main: index == 0
                )

                try await SupabaseManager.shared.client
                    .from("user_photos")
                    .upsert(photo, onConflict: "user_id,url")
                    .execute()
            }

            if let mainItem = images.first, let urlStr = mainItem.url {
                await fetchAndCacheMainImage(from: urlStr)
            }

            print("✅ Photos reordered and synced via UPSERT.")
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
            let profileData = try await SupabaseManager.shared.client.database
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
            let photoResult = try await SupabaseManager.shared.client.database
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
        try await SupabaseManager.shared.client.database
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



}
