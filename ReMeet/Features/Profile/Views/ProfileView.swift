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
        VStack {
            if profile.isLoading {
                ProgressView("Loading profile...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        ProfilePhotoGrid(images: $profilePhotos)

                        // User Info
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

                            // Personality tags
                            TagCategorySelector(
                                tags: personalityTags,
                                selectionLimit: 3,
                                selected: $selectedPersonality
                            )

                            // Placeholder for future editable fields
                            Button("Edit Profile Info") {
                                // Optional: hook to future sheet or editor
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
        }
        .onDisappear {
            Task {
                if imagesHaveChanged(original: originalPhotos, current: profilePhotos),
                   let userId = SupabaseManager.shared.client.auth.currentUser?.id {
                    await SupabasePhotoUploader.shared.uploadUpdatedPhotos(profilePhotos, for: userId)
                }
            }
        }
        .onChange(of: profilePhotos) { newPhotos in
            if let userId = SupabaseManager.shared.client.auth.currentUser?.id {
                SupabasePhotoUploader.shared.syncPhotosIfChanged(current: newPhotos, original: originalPhotos, userID: userId)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
}
