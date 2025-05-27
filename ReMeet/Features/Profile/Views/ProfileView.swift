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
                // Header bar (compact)
                HStack {
                    // Left button (e.g. search or events)
                    Button(action: {
                        // TODO: handle search or event action
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text("Profile")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    // Right button (notifications)
                    Button(action: {
                        // TODO: handle notifications
                    }) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                VStack {
                    if profile.isLoading {
                        ProgressView("Loading profile...")
                    } else {
                        ScrollView {
                            VStack(alignment: .center, spacing: 20) {

                                ProfilePhotoGrid(images: $profilePhotos)
                                    .environmentObject(profile)

                                VStack(alignment: .leading, spacing: 12) {
                                    if let name = profile.firstName, let age = profile.age {
                                        Text("\(name), \(age)")
                                            .font(.title)
                                            .fontWeight(.bold)
                                    } else {
                                        Text("Your name, age")
                                            .font(.title)
                                            .fontWeight(.bold)
                                    }

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
                .onAppear {
                    profilePhotos = profile.cachedProfileImages
                    originalPhotos = profile.cachedProfileImages

                    Task {
                        await profile.refreshUserPhotoFromNetwork()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
                    if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                        profile.userImage = refreshed
                    }
                }
                .onDisappear {
                    Task.detached {
                        await profile.syncReorderedPhotos(profilePhotos)
                    }

                }
                .onChange(of: profilePhotos) { newPhotos in
                    profile.cachedProfileImages = newPhotos // live update
                    Task.detached {
                        await profile.syncReorderedPhotos(newPhotos) // async background sync
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
}
