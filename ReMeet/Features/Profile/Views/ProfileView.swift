//
//  ProfileView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
import UIKit
import Foundation

struct ProfileView: View {
    @EnvironmentObject var profile: ProfileStore
    @State private var selectedPersonality: Set<SelectableTag> = []
    @State private var profilePhotos: [ImageItem] = []
    @State private var originalPhotos: [ImageItem] = []

    let personalityTags = [
        SelectableTag(label: "Introvert", iconName: "moon"),
        SelectableTag(label: "Extrovert", iconName: "sun.max"),
        SelectableTag(label: "Funny", iconName: "face.smiling"),
        SelectableTag(label: "Open-minded", iconName: "sparkles")
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                headerBar

                VStack {
                    if profile.isLoading {
                        ProgressView("Loading profile...")
                    } else {
                        ScrollView {
                            VStack(alignment: .center, spacing: 20) {
                                ProfilePhotoGrid(images: $profilePhotos)
                                    .environmentObject(profile)

                                VStack(alignment: .leading, spacing: 12) {
                                    Text(profileNameAndAge)
                                        .font(.title)
                                        .fontWeight(.bold)

                                    TagCategorySelector(
                                        tags: personalityTags,
                                        selectionLimit: 3,
                                        selected: $selectedPersonality
                                    )

                                    Button("Edit Profile Info") {
                                        // Hook to edit sheet
                                    }
                                    .padding(.top)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top)
                        }
                    }

                    Spacer()
                }
                .task {
                    // ✅ Step 1: Load profile info + URLs first
                    if !profile.hasLoadedOnce || profile.shouldReloadProfile() {
                        await profile.loadEverything()
                    }

                    // ✅ Step 2: Only after URLs are loaded, fetch images
                    profilePhotos = await loadProfileGridPhotos(from: profile.profilePhotoURLs)
                    originalPhotos = profilePhotos

                    // ✅ Step 3: Cache userImage if still missing
                    if profile.userImage == nil {
                        await MainActor.run {
                            if let main = profilePhotos.first?.image {
                                profile.userImage = main
                            } else {
                                profile.loadCachedOrFetchUserPhoto()
                            }
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
                    if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                        profile.userImage = refreshed
                    }
                    if let image = profilePhotos.first?.image {
                        profile.userImage = image // 💥 Force update from reordered list
                    }
                }
                .onChange(of: profilePhotos) {
                    Task.detached {
                        await profile.syncReorderedPhotos(profilePhotos)
                    }
                }

            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()

            Text("Profile")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button(action: {}) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var profileNameAndAge: String {
        if let name = profile.firstName, let age = profile.age {
            return "\(name), \(age)"
        } else {
            return "Your name, age"
        }
    }
    
    func loadProfileGridPhotos(from urls: [String]) async -> [ImageItem] {
        var items: [ImageItem] = []

        for (index, urlStr) in urls.enumerated() {
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


#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
}
