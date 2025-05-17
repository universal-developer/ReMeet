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
    @State private var showPhotoEditor = false

    let personalityTags = [
        SelectableTag(label: "Introvert", iconName: "moon"),
        SelectableTag(label: "Extrovert", iconName: "sun.max"),
        SelectableTag(label: "Funny", iconName: "face.smiling"),
        SelectableTag(label: "Open-minded", iconName: "sparkles")
    ]

    var imageItems: [ImageItem] {
        profile.cachedProfileImages
    }

    var body: some View {
        VStack {
            if profile.isLoading {
                ProgressView("Loading profile...")
            } else {
                ScrollView {
                    ProfilePhotosCarousel(images: imageItems)

                    VStack {
                        if let name = profile.firstName, let age = profile.age {
                            Text("\(name), \(age)")
                                .font(.title)
                                .fontWeight(.bold)
                        }

                        TagCategorySelector(
                            tags: personalityTags,
                            selectionLimit: 3,
                            selected: $selectedPersonality
                        )

                        Button("Modify Profile") {
                            showPhotoEditor = true
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }

            Spacer()
        }
        .sheet(isPresented: $showPhotoEditor) {
            PhotoEditorView(imageItems: .constant(imageItems))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
}
