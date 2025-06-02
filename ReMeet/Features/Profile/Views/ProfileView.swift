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
                    profile.loadCachedOrFetchUserPhoto()

                    if !profile.hasLoadedOnce || profile.shouldReloadProfile() {
                        await profile.loadEverything()
                    }

                    profilePhotos = profile.cachedProfileImages
                    originalPhotos = profile.cachedProfileImages
                }
                .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
                    if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                        profile.userImage = refreshed
                    }
                }
                .onChange(of: profilePhotos) { newPhotos in
                    guard newPhotos != originalPhotos else { return }
                    profile.cachedProfileImages = newPhotos
                    originalPhotos = newPhotos
                    Task.detached {
                        await profile.syncReorderedPhotos(newPhotos)
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
}


#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
}
