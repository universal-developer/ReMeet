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
    @State private var isLoading = false // Only true when actually loading from network
    @State private var isShowingEditSheet = false
    @State private var highlightEditButton = false
    
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                headerBar

                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        // Show shimmer only when actually loading from network
                        if isLoading {
                            shimmerPhotoGrid
                        } else {
                            ProfilePhotoGrid(images: $profile.preloadedProfilePhotos)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(profileNameAndAge)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            /*Text("Photos loaded: \(profile.preloadedProfilePhotos.count)")
                             .font(.caption)*/
                            if let city = profile.city, !city.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                    Text(city)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }

                Spacer()
            }
            .onAppear {
                // Only load if we haven't loaded before or if we have no photos
                if !profile.hasLoadedOnce || profile.preloadedProfilePhotos.isEmpty {
                    isLoading = true
                    Task {
                        await profile.loadProfileAndPhotos()
                        await MainActor.run {
                            isLoading = false
                        }
                    }
                }
                
                // Set user image if not already set
                if profile.userImage == nil,
                   let main = profile.preloadedProfilePhotos.first(where: { $0.isMain })?.image {
                    profile.userImage = main
                }
                
                if profile.city == nil || profile.city?.isEmpty == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        highlightEditButton = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
                if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                    profile.userImage = refreshed
                }
                if let image = profile.preloadedProfilePhotos.first(where: \.isMain)?.image {
                    profile.userImage = image
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                editProfileSheet
            }
        }
    }
    
    
    private var shimmerPhotoGrid: some View {
        VStack {
            GeometryReader { geo in
                let width = geo.size.width
                let spacing: CGFloat = 8
                let full = width - spacing * 2
                let smallSize = (full - spacing * 2) / 3
                let largeHeight = smallSize * 2 + spacing

                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        // Large placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: smallSize * 2 + spacing, height: largeHeight)
                            .shimmering()

                        VStack(spacing: spacing) {
                            // Small placeholders
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: smallSize, height: smallSize)
                                .shimmering()
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: smallSize, height: smallSize)
                                .shimmering()
                        }
                    }

                    HStack(spacing: spacing) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: smallSize, height: smallSize)
                                .shimmering()
                        }
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.width * 0.95)
        }
        .padding(.horizontal)
    }

    private var headerBar: some View {
        HStack {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Spacer()

            /*Button(action: {
                // TODO: Open profile editing view
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }*/
            
            Button(action: {
                isShowingEditSheet = true
                highlightEditButton = false
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "C9155A"), lineWidth: highlightEditButton ? 2 : 0)
                            .scaleEffect(highlightEditButton ? 1.2 : 1.0)
                            .opacity(highlightEditButton ? 1.0 : 0)
                            .animation(.easeInOut(duration: 1.2).repeatCount(3, autoreverses: true), value: highlightEditButton)
                    )
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
    
    private var editProfileSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Photos")) {
                    EditablePhotoGrid(images: $profile.preloadedProfilePhotos)
                }

                Section(header: Text("Name")) {
                    TextField("Your name", text: Binding(
                        get: { profile.firstName ?? "" },
                        set: { profile.firstName = $0 }
                    ))
                }

                Section(header: Text("Age")) {
                    TextField("Your age", value: Binding(
                        get: { profile.age ?? 18 },
                        set: { profile.age = max(18, $0) } // 👈 forces >= 18
                    ), format: .number)
                    .keyboardType(.numberPad)
                }

                Section(header: Text("City")) {
                    TextField(profile.city?.isEmpty == false ? "" : "Add your city", text: Binding(
                        get: { profile.city ?? "" },
                        set: { profile.city = $0 }
                    ))
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isShowingEditSheet = false
                    }
                }
            }
        }
    }

}

#Preview {
    let store = ProfileStore.shared

    // Mock basic profile data
    store.firstName = "Artush"
    store.age = 18
    store.preloadedProfilePhotos = [
        ImageItem(image: UIImage(systemName: "person.fill")!, isMain: true),
        ImageItem(image: UIImage(systemName: "person.fill")!),
        ImageItem(image: UIImage(systemName: "person.fill")!)
    ]
    store.userImage = store.preloadedProfilePhotos.first?.image
    store.hasLoadedOnce = true

    return ProfileView()
        .environmentObject(store)
}
