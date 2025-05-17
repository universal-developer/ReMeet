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
    @Published var profilePhotoURLs: [String] = []
    @Published var cachedProfileImages: [ImageItem] = []



    func loadEverything() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            // 1. Get session and user ID
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            self.userId = userId

            // 2. Load profile basic info
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

            // 3. Load main profile photo (for QR & tab)
            let mainPhoto: [UserPhoto] = try await SupabaseManager.shared.client
                .from("user_photos")
                .select("url")
                .eq("user_id", value: userId)
                .eq("is_main", value: true)
                .limit(1)
                .execute()
                .value

            if let urlStr = mainPhoto.first?.url,
               let url = URL(string: urlStr) {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.userImage = image
                    }
                    let key = "user_photo_main"
                    ImageCacheManager.shared.setToRAM(image, forKey: key)
                    ImageCacheManager.shared.saveToDisk(image, forKey: key)
                }
            }

            // 4. Load all profile photos
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

            // 5. Load each image from cache or Supabase if missing
            var imageItems: [ImageItem] = []

            for (i, urlStr) in urls.enumerated() {
                guard let url = URL(string: urlStr) else { continue }
                let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: urlStr))"

                if let ramImage = ImageCacheManager.shared.getFromRAM(forKey: key) {
                    imageItems.append(ImageItem(image: ramImage, isMain: i == 0))
                    continue
                }

                if let diskImage = ImageCacheManager.shared.loadFromDisk(forKey: key) {
                    ImageCacheManager.shared.setToRAM(diskImage, forKey: key)
                    imageItems.append(ImageItem(image: diskImage, isMain: i == 0))
                    continue
                }

                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        ImageCacheManager.shared.setToRAM(image, forKey: key)
                        ImageCacheManager.shared.saveToDisk(image, forKey: key)
                        imageItems.append(ImageItem(image: image, isMain: i == 0))
                        print("📸 Cached profile photo \(i)")
                    }
                } catch {
                    print("❌ Couldn’t fetch image from \(urlStr): \(error)")
                }
            }

            await MainActor.run {
                self.cachedProfileImages = imageItems
                self.isLoading = false
                print("✅ Profile fully loaded and cached.")
            }

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("❌ Failed to load profile: \(error)")
            }
        }
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




    struct UserProfile: Decodable {
        let first_name: String
        let age: Int
    }

    struct UserPhoto: Decodable {
        let url: String
    }
}
