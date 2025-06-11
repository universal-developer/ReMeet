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
    @State private var hasInitializedPhotos = false

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

                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        if !profile.hasLoadedOnce {
                            ProfilePhotoGrid(images: $profilePhotos)
                                .redacted(reason: .placeholder)
                                .shimmering()
                        } else {
                            ProfilePhotoGrid(images: $profilePhotos)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(profileNameAndAge)
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Photos loaded: \(profilePhotos.count)")
                                .font(.caption)

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

                Spacer()
            }
            .task {
                if !hasInitializedPhotos {
                    profilePhotos = profile.preloadedProfilePhotos
                    hasInitializedPhotos = true
                }

                if profile.userImage == nil,
                   let main = profilePhotos.first(where: { $0.isMain })?.image {
                    profile.userImage = main
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
                if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                    profile.userImage = refreshed
                }
                if let image = profilePhotos.first(where: \.isMain)?.image {
                    profile.userImage = image
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
