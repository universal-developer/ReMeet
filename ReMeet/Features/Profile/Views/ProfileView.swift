//
//  ProfileView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profile: ProfileStore
    @State private var imageItems: [ImageItem] = []
    @State private var showPhotoEditor = false

    var body: some View {
        VStack {
            if profile.isLoading {
                ProgressView("Loading profile...")
            } else {
                ProfilePhotosCarousel()
                
                VStack {
                    if let name = profile.firstName, let age = profile.age {
                        Text("\(name), \(age)")
                            .font(.title)
                            .fontWeight(.bold)
                    }


                    WrapTags(tags: ["Bachelors", "Gym rat", "Dog lover", "Big texter"])

                    Button("Modify Profile") {
                        showPhotoEditor = true
                    }
                    .padding(.top)
                }
                .padding()
            }

            Spacer()
        }
        .onAppear {
            Task {
                await profile.load()
                print("🧪 name: \(profile.firstName ?? "nil"), age: \(profile.age.map(String.init) ?? "nil")")


                // Load photo URLs into ImageItems
                imageItems = await loadImageItems(from: profile.profilePhotoURLs)
            }
        }
        .sheet(isPresented: $showPhotoEditor) {
            PhotoEditorView(imageItems: $imageItems)
        }
    }

    func loadImageItems(from urls: [String]) async -> [ImageItem] {
        var items: [ImageItem] = []
        for (i, urlString) in urls.enumerated() {
            if let url = URL(string: urlString),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                items.append(ImageItem(image: image, isMain: i == 0))
            }
        }
        return items
    }
}


#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
}

