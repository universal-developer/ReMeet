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
    @State private var selectedImage: ImageItem?

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
                    VStack(alignment: .leading, spacing: 20) {

                        PhotoGridView(images: imageItems, onPlaceholderTapped: {
                            showPhotoEditor = true
                        })


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
                                showPhotoEditor = true
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
        .sheet(isPresented: $showPhotoEditor) {
            PhotoEditorView(imageItems: .constant([]))
        }
    }

    @ViewBuilder
    private func placeholderCell(size: CGFloat, width: CGFloat? = nil) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(width: width ?? size, height: size)
                .foregroundColor(.gray)

            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
}
