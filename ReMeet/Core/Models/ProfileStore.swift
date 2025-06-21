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
    static let shared = ProfileStore()

    // MARK: - Profile Info
    @Published var userId: String?
    @Published var firstName: String?
    @Published var age: Int?
    @Published var city: String? = nil

    // MARK: - Photos
    @Published var preloadedProfilePhotos: [ImageItem] = []
    @Published var userImage: UIImage?
    @Published var profilePhotoURLs: [String] = []
    @Published var hasLoadedOnce: Bool = false
    @Published var isLoading: Bool = false

    private init() {}

    // MARK: - Load all user data
    func loadProfileAndPhotos() async {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            self.userId = userId

            // Load basic profile
            let profiles: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("first_name, age")
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            self.firstName = profiles.first?.first_name
            self.age = profiles.first?.age

            // Load user photos
            let allPhotos: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url, is_main")
                .eq("user_id", value: userId)
                .order("sort_order", ascending: true)
                .execute()
                .value

            let urls = allPhotos.map { $0.url }
            self.profilePhotoURLs = urls

            var images: [ImageItem] = []

            // Load images concurrently for better performance
            await withTaskGroup(of: (Int, ImageItem?).self) { group in
                for (index, photo) in allPhotos.enumerated() {
                    group.addTask {
                        let urlStr = photo.url
                        let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: urlStr))"

                        // Check cache first
                        if let cached = ImageCacheManager.shared.getFromRAM(forKey: key) ??
                                        ImageCacheManager.shared.loadFromDisk(forKey: key) {
                            ImageCacheManager.shared.setToRAM(cached, forKey: key)
                            return (index, ImageItem(image: cached, isMain: photo.is_main, url: urlStr))
                        }
                        
                        // Load from network
                        guard let url = URL(string: urlStr) else { return (index, nil) }
                        
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                ImageCacheManager.shared.setToRAM(image, forKey: key)
                                ImageCacheManager.shared.saveToDisk(image, forKey: key)
                                return (index, ImageItem(image: image, isMain: photo.is_main, url: urlStr))
                            }
                        } catch {
                            print("❌ Failed to load image at \(urlStr): \(error)")
                        }
                        
                        return (index, nil)
                    }
                }
                
                // Collect results in order
                var indexedImages: [(Int, ImageItem)] = []
                for await result in group {
                    if let imageItem = result.1 {
                        indexedImages.append((result.0, imageItem))
                    }
                }
                
                // Sort by original index and extract images
                images = indexedImages.sorted { $0.0 < $1.0 }.map { $0.1 }
            }

            self.preloadedProfilePhotos = images

            if let main = images.first(where: { $0.isMain })?.image {
                self.userImage = main
                ImageCacheManager.shared.setToRAM(main, forKey: "user_photo_main")
                ImageCacheManager.shared.saveToDisk(main, forKey: "user_photo_main")
            }
            
            self.hasLoadedOnce = true

        } catch {
            print("❌ Failed to load profile + photos: \(error)")
        }
    }

    // MARK: - Refresh photos only (for when user updates photos)
    func refreshPhotos() async {
        guard let userId = self.userId else { return }
        
        do {
            let allPhotos: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url, is_main")
                .eq("user_id", value: userId)
                .order("sort_order", ascending: true)
                .execute()
                .value

            var images: [ImageItem] = []
            
            for photo in allPhotos {
                let urlStr = photo.url
                let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: urlStr))"

                if let cached = ImageCacheManager.shared.getFromRAM(forKey: key) ??
                                ImageCacheManager.shared.loadFromDisk(forKey: key) {
                    images.append(ImageItem(image: cached, isMain: photo.is_main, url: urlStr))
                }
            }
            
            self.preloadedProfilePhotos = images
            self.profilePhotoURLs = allPhotos.map { $0.url }
            
            if let main = images.first(where: { $0.isMain })?.image {
                self.userImage = main
                ImageCacheManager.shared.setToRAM(main, forKey: "user_photo_main")
                ImageCacheManager.shared.saveToDisk(main, forKey: "user_photo_main")
            }
            
        } catch {
            print("❌ Failed to refresh photos: \(error)")
        }
    }

    // MARK: - Fetch other user's minimal profile
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

    // MARK: - Models
    struct UserProfile: Decodable {
        let first_name: String
        let age: Int
    }

    struct UserPhoto: Decodable {
        let url: String
        let is_main: Bool
    }

    struct MinimalUser: Identifiable {
        let id: String
        let firstName: String
        let image: UIImage?
    }
}
