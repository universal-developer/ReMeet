//
//  ProfileStore.swift
//  ReMeet
//
//  Refactored to use ProfileService, FriendsService, and ImageFetcher.
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
    @Published var city: String?

    // MARK: - Photos
    @Published var preloadedProfilePhotos: [ImageItem] = []
    @Published var userImage: UIImage?
    @Published var profilePhotoURLs: [String] = []
    @Published var hasLoadedOnce: Bool = false
    @Published var isLoading: Bool = false

    // MARK: - Friends
    @Published var friends: [MinimalUser] = []

    private init() {}

    // MARK: - Load profile and photos
    func loadProfileAndPhotos() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            self.userId = userId

            let (profile, allPhotos) = try await ProfileService.getCurrentProfileAndPhotos(userId: userId)

            self.firstName = profile?.first_name
            self.age = profile?.age
            self.profilePhotoURLs = allPhotos.map { $0.url }

            var images: [ImageItem] = []

            await withTaskGroup(of: (Int, ImageItem?).self) { group in
                for (index, photo) in allPhotos.enumerated() {
                    group.addTask {
                        let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: photo.url))"
                        let image = await ImageFetcher.loadAndCacheImage(from: photo.url, cacheKey: key)
                        if let image = image {
                            return (index, ImageItem(image: image, isMain: photo.is_main, url: photo.url))
                        }
                        return (index, nil)
                    }
                }

                var indexed: [(Int, ImageItem)] = []
                for await result in group {
                    if let item = result.1 {
                        indexed.append((result.0, item))
                    }
                }

                images = indexed.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
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

    // MARK: - Refresh photos only
    func refreshPhotos() async {
        guard let userId = userId else { return }

        do {
            let photos = try await ProfileService.getCurrentProfileAndPhotos(userId: userId).1
            var images: [ImageItem] = []

            for photo in photos {
                let key = "user_photo_\(ImageCacheManager.shared.stableHash(for: photo.url))"
                if let cached = ImageCacheManager.shared.getFromRAM(forKey: key) ??
                                ImageCacheManager.shared.loadFromDisk(forKey: key) {
                    images.append(ImageItem(image: cached, isMain: photo.is_main, url: photo.url))
                }
            }

            self.preloadedProfilePhotos = images
            self.profilePhotoURLs = photos.map { $0.url }

            if let main = images.first(where: { $0.isMain })?.image {
                self.userImage = main
                ImageCacheManager.shared.setToRAM(main, forKey: "user_photo_main")
                ImageCacheManager.shared.saveToDisk(main, forKey: "user_photo_main")
            }
        } catch {
            print("❌ Failed to refresh photos: \(error)")
        }
    }

    // MARK: - Minimal user info (used on map, QR, etc)
    func fetchMinimalUser(userId: String) async -> MinimalUser? {
        await ProfileService.fetchMinimalUser(userId: userId)
    }

    // MARK: - Add friend
    func confirmFriendAdd(myId: String, friendId: String) async {
        await FriendsService.confirmFriendAdd(myId: myId, friendId: friendId)
    }

    // MARK: - Load friends
    func loadFriends() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let myId = session.user.id.uuidString
            let fetched = await FriendsService.fetchFriends(myId: myId)
            self.friends = fetched
        } catch {
            print("❌ Failed to load friends: \(error.localizedDescription)")
            self.friends = []
        }
    }
}
